# frozen_string_literal: true

module SpreeRazorpay
  class Gateway < ::Spree::Gateway
    module PaymentSessions
      extend ActiveSupport::Concern

      def session_required?
        true
      end

      def payment_session_class
        Spree::PaymentSessions::Razorpay
      end

      def create_payment_session(order:, amount: nil, external_data: {})
        total = amount.presence || order.total_minus_store_credits
        amount_in_paise = (total * 100).to_i
        raise Spree::Core::GatewayError, 'Amount must be greater than zero' if amount_in_paise.zero?

        razorpay_order = client.order.create(
          amount: amount_in_paise,
          currency: order.currency,
          receipt: order.number,
          notes: {
            spree_order_id: order.id,
            spree_order_number: order.number
          }
        )

        address = order.ship_address || order.bill_address
        customer_name = address ? "#{address.first_name} #{address.last_name}".strip : nil
        customer_email = order.email.presence || (order.respond_to?(:user) ? order.user&.email : nil)
        customer_phone = address&.phone.presence

        payment_session_class.create!(
          owner: order,
          payment_method: self,
          amount: total,
          currency: order.currency,
          status: 'pending',
          external_id: razorpay_order.id,
          external_data: {
            'key_id' => preferred_key_id,
            'razorpay_order_id' => razorpay_order.id,
            'amount_in_paise' => amount_in_paise,
            'customer_name' => customer_name,
            'customer_email' => customer_email,
            'customer_phone' => customer_phone
          }.compact
        )
      end

      def complete_payment_session(payment_session:, params: {})
        raw_ext = params[:external_data] || params['external_data'] || {}
        ext = raw_ext.respond_to?(:to_h) ? raw_ext.to_h.with_indifferent_access : {}
        razorpay_payment_id = params[:razorpay_payment_id] || params['razorpay_payment_id'] || ext[:razorpay_payment_id]
        razorpay_signature = params[:razorpay_signature] || params['razorpay_signature'] || ext[:razorpay_signature]

        generated_signature = OpenSSL::HMAC.hexdigest(
          'sha256',
          preferred_key_secret,
          "#{payment_session.external_id}|#{razorpay_payment_id}"
        )

        unless ActiveSupport::SecurityUtils.secure_compare(generated_signature, razorpay_signature.to_s)
          Rails.logger.error("[SpreeRazorpay] Signature mismatch for session #{payment_session.id}. Generated: #{generated_signature}, Received: #{razorpay_signature}")
          payment_session.fail if payment_session.can_fail?
          return payment_session
        end

        payment_session.process if payment_session.can_process?
        payment_session.update!(
          external_data: (payment_session.external_data || {}).merge(
            'razorpay_payment_id' => razorpay_payment_id
          )
        )

        payment_session.settle_payment!(captured: preferred_auto_capture)
        payment_session.complete unless payment_session.completed?
        payment_session
      rescue StandardError => e
        Rails.logger.error("[SpreeRazorpay] Exception in complete_payment_session: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
        payment_session.fail if payment_session.can_fail?
        payment_session
      end
    end
  end
end
