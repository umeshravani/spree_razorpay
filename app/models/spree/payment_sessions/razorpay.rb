module Spree
  module PaymentSessions
    class Razorpay < Spree::PaymentSession

      def client_key
        external_data['client_key']
      end
      
      def razorpay_order_id
        external_id
      end

      def find_or_create_payment!(metadata = {})
        return unless persisted?
        return payment if payment.present?

        order.with_lock do
          rzp_payment_id = external_data['razorpay_payment_id']
          
          existing_payment = order.payments.where(
            payment_method: payment_method,
            response_code: rzp_payment_id || external_id
          ).first

          return existing_payment if existing_payment.present?

          source = ::Spree::RazorpayCheckout.create!(
            order_id: order.id,
            razorpay_payment_id: rzp_payment_id,
            razorpay_order_id: external_id,
            razorpay_signature: external_data['razorpay_signature'],
            status: 'captured',
            payment_method: payment_method.name
          )

          order.payments.create!(
            payment_method: payment_method,
            amount: amount,
            response_code: rzp_payment_id || external_id,
            source: source,
            skip_source_requirement: true
          )
        end
      end

    end
  end
end
