# frozen_string_literal: true

module SpreeRazorpay
  class Gateway < Spree::Gateway
    include SpreeRazorpay::Gateway::PaymentSessions
    include SpreeRazorpay::Gateway::Webhooks

    self.accepts_money_amounts = true

    preference :key_id, :string
    preference :key_secret, :password
    preference :webhook_secret, :password
    preference :auto_capture, :boolean, default: true

    validates :preferred_key_id, :preferred_key_secret, presence: true

    RAZORPAY_SVG_PATH = File.expand_path('../../assets/images/spree_razorpay/razorpay-icon.svg', __dir__)
    RAZORPAY_PNG_PATH = File.expand_path('../../assets/images/spree_razorpay/razorpay-icon.png', __dir__)

    def self.logo_url
      if File.exist?(RAZORPAY_SVG_PATH)
        "data:image/svg+xml;base64,#{Base64.strict_encode64(File.read(RAZORPAY_SVG_PATH))}"
      elsif File.exist?(RAZORPAY_PNG_PATH)
        "data:image/png;base64,#{Base64.strict_encode64(File.read(RAZORPAY_PNG_PATH))}"
      else
        'https://cdn.razorpay.com/static/assets/logo/payment.svg'
      end
    end

    def self.docs_url
      'https://razorpay.com/docs/payments/payment-gateway'
    end

    def provider_class
      self.class
    end

    def method_type
      'spree_razorpay'
    end

    def payment_icon_name
      'razorpay'
    end

    def authorize(amount, source, gateway_options = {})
      handle_authorize_or_purchase(amount, source, gateway_options)
    end

    def purchase(amount, source, gateway_options = {})
      handle_authorize_or_purchase(amount, source, gateway_options)
    end

    def capture(amount, response_code, _gateway_options = {})
      protect_from_error do
        amount_in_paise = amount.is_a?(Spree::Money) ? (amount.to_d * 100).to_i : amount.to_i
        payment = client.payment.fetch(response_code)
        payment = payment.capture({ amount: amount_in_paise })
        success(payment.id, payment.attributes)
      end
    end

    # The `credit` method is called by Spree when generating a Refund from the dashboard.
    # With accepts_money_amounts = true, money is passed as Spree::Money (or subunit integer).
    def credit(money, transaction_id, _options = {})
      protect_from_error do
        client = Razorpay::Client.new(preferred_key_id, preferred_key_secret)
        amount_in_paise = money.is_a?(Spree::Money) ? (money.to_d * 100).to_i : money.to_i

        refund = client.refund.create(payment_id: transaction_id, amount: amount_in_paise)

        Spree::PaymentResponse.new(
          true,
          'Razorpay Refund Successful',
          { id: refund.id, status: refund.status },
          authorization: refund.id
        )
      end
    rescue StandardError => e
      Spree::PaymentResponse.new(false, "Razorpay Refund Failed: #{e.message}")
    end

    def void(response_code, _gateway_options = {})
      cancel(response_code)
    end

    # The `cancel` method is called by Spree when voiding or cancelling a payment.
    def cancel(transaction_id, _payment = nil, refund: true)
      protect_from_error do
        client = Razorpay::Client.new(preferred_key_id, preferred_key_secret)
        refund_record = client.refund.create(payment_id: transaction_id)

        Spree::PaymentResponse.new(
          true,
          'Razorpay Cancellation Successful',
          { id: refund_record.id, status: refund_record.status },
          authorization: refund_record.id
        )
      end
    rescue StandardError => e
      Spree::PaymentResponse.new(false, "Razorpay Cancellation Failed: #{e.message}")
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
