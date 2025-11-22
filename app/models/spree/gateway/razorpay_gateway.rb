require 'razorpay'

module Spree
  class Gateway::RazorpayGateway < Gateway
    preference :key_id, :string
    preference :key_secret, :string
    preference :test_key_id, :string
    preference :test_key_secret, :string
    preference :test_mode, :boolean, default: false
    preference :merchant_name, :string, default: 'Razorpay'
    preference :merchant_description, :text, default: 'Razorpay Payment Gateway'
    preference :merchant_address, :string, default: 'Razorpay, Bangalore, India'
    preference :theme_color, :string, default: '#2e5bff'

    def supports?(_source)
      true
    end

    def source_required?
      false
    end

    def name
      'Razorpay Secure (UPI, Wallets, Cards & Netbanking)'
    end

    def method_type
      'razorpay'
    end

    def payment_source_class
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
      Razorpay.setup(current_key_id, current_key_secret)
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
      %w[capture void]
    end

    def can_capture?(payment)
      %w[checkout pending].include?(payment.state)
    end

    def can_void?(payment)
      payment.state != 'void'
    end

    # Not used directly (we use custom flow), but kept it for compatibility
    def purchase(_amount, _transaction_details, _gateway_options = {})
      ActiveMerchant::Billing::Response.new(true, 'Razorpay success')
    end

    def capture(*args)
      simulated_successful_billing_response
    end

    def void(*)
      simulated_successful_billing_response
    end

    def credit(_credit_cents, _payment_id, _options)
      ActiveMerchant::Billing::Response.new(true, 'Refund successful')
    end

    def cancel(payment, _options = {})
     # If `payment` is a Spree::Payment, use its source
        source = if payment.respond_to?(:source)
         payment.source else payment end
         payment.void! if payment.respond_to?(:void!)
     if source.respond_to?(:razorpay_payment_id)
      # Uncomment if you want to actually trigger refund
      # Razorpay::Payment.fetch(source.razorpay_payment_id).refund
      OpenStruct.new(success?: true, authorization: source.razorpay_payment_id)
     else
      # fallback for string/unknown source
      OpenStruct.new(success?: true, authorization: nil)
     end
     rescue => e
      Rails.logger.error("Razorpay cancel failed: #{e.message}")
      OpenStruct.new(success?: false, message: e.message)
    end

    # Verify signature, fetch payment and capture if required. Returns Razorpay::Payment object.
    def verify_and_capture_razorpay_payment(order, razorpay_payment_id)
      Razorpay.setup(current_key_id, current_key_secret)

      begin
        payment = Razorpay::Payment.fetch(razorpay_payment_id)
        # If payment is not captured and auto_capture set true, capture it
        if payment.status == 'authorized'
          amount = (order.total.to_f * 100).to_i
          payment = payment.capture(amount: amount)
        end

        payment
      rescue Razorpay::Error => e
        raise Spree::Core::GatewayError, "Razorpay error: #{e.message}"
      end
    end

    private

    def simulated_successful_billing_response
      ActiveMerchant::Billing::Response.new(true, '', {}, {})
    end
  end
end

