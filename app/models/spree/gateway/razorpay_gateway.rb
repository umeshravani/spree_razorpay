require 'razorpay'

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

    def supports?(_source)
      true
    end

    def source_required?
      true
    end

    def payment_source_class
      Spree::RazorpayCheckout
    end

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

    def purchase(_amount, source, _gateway_options = {})
      provider

      begin
        if source.razorpay_payment_id.blank? || source.razorpay_signature.blank?
           return ActiveMerchant::Billing::Response.new(false, 'Payment was not completed. Please try again.', {}, test: preferred_test_mode)
        end

        # 1. Verify the signature
        ::Razorpay::Utility.verify_payment_signature(
          razorpay_order_id: source.razorpay_order_id,
          razorpay_payment_id: source.razorpay_payment_id,
          razorpay_signature: source.razorpay_signature
        )

        # 2. Safely ensure it is captured!
        rzp_payment = ::Razorpay::Payment.fetch(source.razorpay_payment_id)
        if rzp_payment.status == 'authorized'
          rzp_payment.capture({ amount: _amount })
        end

        source.update!(status: 'captured')
        
        ActiveMerchant::Billing::Response.new(
          true, 
          'Razorpay Payment Successful', 
          {}, 
          test: preferred_test_mode, 
          authorization: source.razorpay_payment_id
        )
        
      rescue StandardError => e
        Rails.logger.error("Razorpay Verification/Capture Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, 'Payment verification failed.', {}, test: preferred_test_mode)
      end
    end

    def capture(*args)
      # We already auto-capture via the frontend/webhook, so we return true to keep Spree happy
      ActiveMerchant::Billing::Response.new(true, 'Already Captured', {}, test: preferred_test_mode)
    end

    # Triggered when you click "Refund" in the Spree Admin
    def credit(credit_cents, response_code, _gateway_options = {})
      provider

      begin
        # Fetch the original payment from Razorpay using the saved payment ID
        rzp_payment = ::Razorpay::Payment.fetch(response_code)
        
        # Issue the refund via Razorpay API (amount must be in paise/cents)
        refund = rzp_payment.refund(amount: credit_cents)

        ActiveMerchant::Billing::Response.new(
          true, 
          'Razorpay Refund Successful', 
          { refund_id: refund.id }, 
          test: preferred_test_mode, 
          authorization: refund.id
        )
      rescue StandardError => e
        Rails.logger.error("Razorpay Refund Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, "Refund failed: #{e.message}", {}, test: preferred_test_mode)
      end
    end

    # Triggered if you explicitly "Void" a payment in Spree
    def void(response_code, _gateway_options = {})
      provider

      begin
        # Razorpay doesn't have a concept of "Voiding" a captured payment, 
        # so we just issue a full refund instead.
        rzp_payment = ::Razorpay::Payment.fetch(response_code)
        refund = rzp_payment.refund

        ActiveMerchant::Billing::Response.new(
          true, 
          'Razorpay Void/Refund Successful', 
          { refund_id: refund.id }, 
          test: preferred_test_mode, 
          authorization: refund.id
        )
      rescue StandardError => e
        Rails.logger.error("Razorpay Void Failed: #{e.message}")
        ActiveMerchant::Billing::Response.new(false, "Void failed: #{e.message}", {}, test: preferred_test_mode)
      end
    end

    # Triggered if the entire Order is Cancelled in the Spree Admin
    def cancel(response_code)
      void(response_code)
    end
  end
end
