module SpreeRazorpay
  class Client
    attr_reader :key_id, :key_secret

    def initialize(key_id:, key_secret:)
      @key_id = key_id
      @key_secret = key_secret
      Razorpay.setup(key_id, key_secret)
    end

    def order
      Razorpay::Order
    end

    def payment
      Razorpay::Payment
    end

    def verify_signature(payload, signature, secret)
      Razorpay::Utility.verify_webhook_signature(payload, signature, secret)
    end
  end
end
