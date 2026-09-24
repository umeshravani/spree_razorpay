# frozen_string_literal: true

module SpreeRazorpay
  class Gateway < Spree::Gateway
    include SpreeRazorpay::Gateway::PaymentSessions
    include SpreeRazorpay::Gateway::Webhooks

    preference :key_id, :string
    preference :key_secret, :password
    preference :webhook_secret, :password
    preference :auto_capture, :boolean, default: true

    validates :preferred_key_id, :preferred_key_secret, presence: true

    def provider_class
      self.class
    end

    def method_type
      'spree_razorpay'
    end

    def payment_icon_name
      'razorpay'
    end



    def authorize(amount, source, gateway_options)
      # Handled asynchronously by webhook or session completion
      ActiveMerchant::Billing::Response.new(true, 'Razorpay Authorized')
    end

    def purchase(amount, source, gateway_options)
      # Handled asynchronously by webhook or session completion
      ActiveMerchant::Billing::Response.new(true, 'Razorpay Purchased')
    end

    def capture(amount, response_code, gateway_options)
      protect_from_error do
        payment = client.payment.fetch(response_code)
        payment = payment.capture({ amount: amount })
        success(payment.id, payment.attributes)
      end
    end

    def credit(amount, response_code, gateway_options)
      protect_from_error do
        payment = client.payment.fetch(response_code)
        refund = payment.refund({ amount: amount })
        success(refund.id, refund.attributes)
      end
    end

    def void(response_code, _gateway_options)
      # Razorpay does not have a void mechanism, we issue a full refund if not captured
      credit(nil, response_code, _gateway_options)
    end

    def cancel(payment_id, payment = nil, refund: true)
      protect_from_error do
        if payment&.completed?
          return success(payment_id, {}) unless refund
          amount = payment.credit_allowed
          return success(payment_id, {}) if amount.zero?

          result = Spree.refund_create_workflow.call(
            payment: payment,
            reason: Spree::RefundReason.order_canceled_reason(payment.owner.store),
            refunder: payment.order&.canceler
          )
          raise Spree::Core::GatewayError, result.error.value.to_s if result.failure?

          success(payment.response_code, result.value.response.params)
        else
          void(payment_id, payment&.source, {})
        end
      end
    end

    def handle_authorize_or_purchase(_amount_in_cents, _payment_source, gateway_options = {})
      prefixed_id = gateway_options[:payment_prefixed_id]
      payment = prefixed_id.present? ? payments.find_by_prefix_id(prefixed_id) : nil

      if payment.blank?
        payment_number = gateway_options[:payment_id].presence || gateway_options[:order_id]
        return failure('Payment number is invalid') if payment_number.blank?
        payment = payments.find_by(number: payment_number)
      end

      return failure('Payment not found') if payment.blank?
      return failure('Payment is missing a Razorpay payment id') if payment.response_code.blank?

      success(payment.response_code, {})
    end

    def gateway_dashboard_payment_url(payment)
      return if payment.transaction_id.blank?
      "https://dashboard.razorpay.com/app/payments/#{payment.transaction_id}"
    end

    def webhook_url
      return nil unless store
      "#{store.url_or_custom_domain}/api/v3/webhooks/payments/#{prefixed_id}"
    end

    def client
      @client ||= SpreeRazorpay::Client.new(key_id: preferred_key_id, key_secret: preferred_key_secret)
    end

    private

    def success(authorization, full_response)
      Spree::PaymentResponse.new(true, nil, full_response.as_json, authorization: authorization)
    end

    def failure(error = nil)
      Spree::PaymentResponse.new(false, error)
    end

    def protect_from_error
      yield
    rescue StandardError => e
      raise Spree::Core::GatewayError, e.message
    end
  end
end
