# frozen_string_literal: true

module Spree
  class PaymentSessions::Razorpay < PaymentSession
    delegate :api_options, to: :payment_method

    def razorpay_order_id
      external_id
    end

    def razorpay_payment_id
      external_data&.dig('razorpay_payment_id')
    end

    def payment_source_for_settlement
      # Create generic payment source representing the Razorpay instrument
      Spree::PaymentSource.create!(
        gateway_payment_profile_id: razorpay_payment_id || external_id,
        payment_method: payment_method
      )
    end

    def apply_settlement_metadata(payment, metadata)
      super
      payment.response_code = razorpay_payment_id if razorpay_payment_id.present?
      payment.metadata['razorpay_order_id'] = external_id
      payment.metadata['razorpay_payment_id'] = razorpay_payment_id
    end
  end
end
