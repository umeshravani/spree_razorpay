# frozen_string_literal: true

module Spree
  module PaymentSessions
    class Razorpay < Spree::PaymentSession
      delegate :api_options, to: :payment_method

      def razorpay_order_id
        external_id
      end

      def razorpay_payment_id
        external_data&.dig('razorpay_payment_id')
      end

      def find_or_create_payment!(metadata = {})
        # Idempotently find existing payment whether keyed by Razorpay Order ID or Payment ID
        existing = owner.payments.where(payment_method: payment_method).where(
          'response_code = ? OR response_code = ?', external_id, razorpay_payment_id
        ).first

        return skip_source_requirement(existing) if existing.present?

        super
      end

      def payment_source_for_settlement
        Spree::PaymentSource.create!(
          gateway_payment_profile_id: razorpay_payment_id || external_id,
          payment_method: payment_method,
          customer: (customer if respond_to?(:customer))
        )
      rescue StandardError => e
        Rails.logger.warn("[SpreeRazorpay] Could not create payment source: #{e.message}")
        nil
      end

      def apply_settlement_metadata(payment, metadata)
        super
        payment.response_code = razorpay_payment_id.presence || external_id
        payment.metadata['razorpay_order_id'] = external_id
        payment.metadata['razorpay_payment_id'] = razorpay_payment_id if razorpay_payment_id.present?
      end
    end
  end
end
