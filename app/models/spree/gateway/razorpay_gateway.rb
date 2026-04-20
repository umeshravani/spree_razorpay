require 'razorpay'
require 'active_merchant'

module Spree
  class Gateway::RazorpayGateway < Gateway
    preference :webhook_secret, :password, default: ''
    preference :key_id, :string, default: ''
    preference :key_secret, :password, default: ''
    preference :test_key_id, :string, default: ''
    preference :test_key_secret, :password, default: ''
    preference :test_mode, :boolean, default: false
    preference :merchant_name, :string, default: 'Razorpay'
    preference :merchant_description, :text, default: 'Razorpay Payment Gateway'
    preference :merchant_address, :string, default: 'Razorpay, Bangalore, India'
    preference :theme_color, :string, default: '#2e5bff'
    preference :headless_api_mode, :boolean, default: false

    def name
      'Razorpay Secure (UPI, Wallets, Cards & Netbanking)'
    end

    def method_type
      'razorpay'
    end

    def payment_icon_name
      'razorpay'
    end

    def description_partial_name
      'razorpay'
    end

    def configuration_guide_partial_name
      'razorpay'
    end

    def provider_class
      self
    end

    def provider
      ::Razorpay.setup(current_key_id, current_key_secret)
    end

    def current_key_id
      preferred_test_mode ? preferred_test_key_id : preferred_key_id
    end

    def current_key_secret
      preferred_test_mode ? preferred_test_key_secret : preferred_key_secret
    end

    def auto_capture?
      true
    end

    def request_type
      'DEFAULT'
    end

    def actions
      %w[capture void credit]
    end

    def can_capture?(payment)
      %w[checkout pending].include?(payment.state)
    end

    def can_void?(payment)
      payment.state != 'void'
    end

    def supports?(_source)
      true
    end

    def session_required?
      preferred_headless_api_mode
    end

    def source_required?
      !preferred_headless_api_mode
    end

    def setup_session_supported?
      false
    end

    def payment_source_class
      Spree::RazorpayCheckout
    end

    def payment_session_class
      Spree::PaymentSessions::Razorpay if defined?(Spree::PaymentSession)
    end

    # SPREE 5.4+ HEADLESS API FLOW (Protected by defined? check)

    if defined?(Spree::PaymentSession)
      def create_payment_session(order:, amount: nil, external_data: {})
        provider
        total = amount || order.total_minus_store_credits
        amount_in_cents = (total.to_f * 100).to_i

        rzp_order = ::Razorpay::Order.create(
          amount: amount_in_cents,
          currency: order.currency || 'INR',
          receipt: order.number,
          payment_capture: 1,
          notes: { spree_order_number: order.number, email: order.email }
        )

        unless rzp_order && rzp_order.attributes.key?('id')
          raise Spree::Core::GatewayError, 'Failed to create Razorpay session'
        end

        payment_sessions.create!(
          type: 'Spree::PaymentSessions::Razorpay',
          order: order,
          amount: total,
          currency: order.currency || 'INR',
          external_id: rzp_order.id,
          external_data: { client_key: current_key_id },
          customer: order.user,
          status: 'pending'
        )
      rescue StandardError => e
        Rails.logger.error("Razorpay Session Creation Failed: #{e.message}")
        raise Spree::Core::GatewayError, e.message
      end

      def update_payment_session(payment_session:, amount: nil, external_data: {})
        provider
        
        if amount.present? && payment_session.amount != amount
          amount_in_cents = (amount.to_f * 100).to_i
          
          new_rzp_order = ::Razorpay::Order.create(
            amount: amount_in_cents,
            currency: payment_session.currency,
            receipt: payment_session.order.number,
            payment_capture: 1
          )
          
          payment_session.update!(amount: amount, external_id: new_rzp_order.id)
        end
        payment_session
      end

      def complete_payment_session(payment_session:, params: {})
        provider
        
        ext_data = params[:external_data] || params['external_data'] || {}
        rzp_payment_id = ext_data[:razorpay_payment_id] || ext_data['razorpay_payment_id'] || payment_session.external_data['razorpay_payment_id']
        rzp_signature  = ext_data[:razorpay_signature] || ext_data['razorpay_signature'] || payment_session.external_data['razorpay_signature']

        begin
          ::Razorpay::Utility.verify_payment_signature(
            razorpay_order_id: payment_session.external_id,
            razorpay_payment_id: rzp_payment_id,
            razorpay_signature: rzp_signature
          )

          rzp_payment = ::Razorpay::Payment.fetch(rzp_payment_id)
          if rzp_payment.status == 'authorized'
            rzp_payment.capture({ amount: (payment_session.amount.to_f * 100).to_i }) 
          end

          payment_session.process! if payment_session.can_process?
          payment = payment_session.find_or_create_payment!
          
          if payment.present? && !payment.completed?
            payment.started_processing! if payment.checkout?
            payment.complete! if payment.can_complete?
          end

          payment_session.complete! if payment_session.can_complete?

        rescue StandardError => e
          Rails.logger.error("Razorpay 5.4 API Completion Failed: #{e.message}")
          payment_session.fail! if payment_session.can_fail?
          raise Spree::Core::GatewayError, e.message
        end
      end

      def parse_webhook_event(raw_body, headers)
        provider
        signature = headers['HTTP_X_RAZORPAY_SIGNATURE'] || headers['X-Razorpay-Signature']

        unless ::Razorpay::Utility.verify_webhook_signature(raw_body, signature, preferred_webhook_secret)
          raise Spree::PaymentMethod::WebhookSignatureError
        end

        event = JSON.parse(raw_body)
        payment_entity = event.dig('payload', 'payment', 'entity') || event.dig('payload', 'order', 'entity')
        
        session = Spree::PaymentSession.find_by(external_id: payment_entity['order_id'])
        return nil unless session

        case event['event']
        when 'payment.captured', 'payment.authorized'
          { action: :captured, payment_session: session }
        when 'payment.failed'
          { action: :failed, payment_session: session }
        else
          nil
        end
      rescue ::Razorpay::Errors::SignatureVerificationError
        raise Spree::PaymentMethod::WebhookSignatureError
      end
    end

    def purchase(_amount, source, _gateway_options = {})
      provider

      begin
        if source.razorpay_payment_id.blank? || source.razorpay_signature.blank?
           return ActiveMerchant::Billing::Response.new(false, 'Payment was not completed. Please try again.', {}, test: preferred_test_mode)
        end

        ::Razorpay::Utility.verify_payment_signature(
          razorpay_order_id: source.razorpay_order_id,
          razorpay_payment_id: source.razorpay_payment_id,
          razorpay_signature: source.razorpay_signature
        )

        rzp_payment = ::Razorpay::Payment.fetch(source.razorpay_payment_id)
        if rzp_payment.status == 'authorized'
          rzp_payment.capture({ amount: _amount })
        end

        source.update!(status: 'captured')
        
        ActiveMerchant::Billing::Response.new(true, 'Razorpay Payment Successful', {}, test: preferred_test_mode, authorization: source.razorpay_payment_id)
        
      rescue StandardError => e
        Rails.logger.error("Razorpay Verification/Capture Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, 'Payment verification failed.', {}, test: preferred_test_mode)
      end
    end

def resolve_razorpay_payment_id(response_code)
      return nil if response_code.blank?

      if response_code.to_s.start_with?('order_')
        rzp_order = ::Razorpay::Order.fetch(response_code)
        payments = rzp_order.payments
        
        captured_payment = payments.items.find { |p| p.status == 'captured' } || payments.items.first
        
        raise StandardError, "No captured payment found for Razorpay Order #{response_code}" unless captured_payment
        
        captured_payment.id
      else
        response_code
      end
    end

    def capture(*args)
      ActiveMerchant::Billing::Response.new(true, 'Already Captured', {}, test: preferred_test_mode)
    end

    def credit(credit_cents, response_code, _gateway_options = {})
      provider
      begin
        rzp_payment_id = resolve_razorpay_payment_id(response_code)
        
        if rzp_payment_id.blank?
          raise StandardError, "Missing Razorpay Payment ID. Cannot process refund."
        end
        
        refund = ::Razorpay::Refund.create(payment_id: rzp_payment_id, amount: credit_cents.to_i)
        
        ActiveMerchant::Billing::Response.new(true, 'Razorpay Refund Successful', { refund_id: refund.id }, test: preferred_test_mode, authorization: refund.id)
      rescue StandardError => e
        Rails.logger.error("Razorpay Refund Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, "Refund failed: #{e.message}", {}, test: preferred_test_mode)
      end
    end

    def void(response_code, _gateway_options = {})
      provider
      begin
        rzp_payment_id = resolve_razorpay_payment_id(response_code)

        if rzp_payment_id.blank?
          raise StandardError, "Missing Razorpay Payment ID. Cannot process void."
        end

        refund = ::Razorpay::Refund.create(payment_id: rzp_payment_id)
        
        ActiveMerchant::Billing::Response.new(true, 'Razorpay Void/Refund Successful', { refund_id: refund.id }, test: preferred_test_mode, authorization: refund.id)
      rescue StandardError => e
        Rails.logger.error("Razorpay Void Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, "Void failed: #{e.message}", {}, test: preferred_test_mode)
      end
    end

    def cancel(response_code, _source = nil, _options = {})
      void(response_code)
    end
  end
end
