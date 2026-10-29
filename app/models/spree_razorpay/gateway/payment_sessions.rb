# frozen_string_literal: true

require 'openssl'
require 'active_support/security_utils'

module SpreeRazorpay
  class Gateway < ::Spree::Gateway
    module PaymentSessions
      extend ActiveSupport::Concern

      def session_required?
        true
      end

      def source_required?
        false
      end

      def payment_session_class
        Spree::PaymentSessions::Razorpay
      end

      def create_payment_session(order:, amount: nil, external_data: {})
        total = (amount.presence || order.total_minus_store_credits).to_d
        amount_in_paise = (total * 100).to_i
        raise Spree::Core::GatewayError, 'Amount must be greater than zero' if amount_in_paise <= 0

        # Cancel any previous open sessions for this cart and payment method to prevent double-charges
        if order.respond_to?(:payment_sessions)
          order.payment_sessions.where(payment_method: self, status: %w[pending processing]).find_each do |open_session|
            cancel_payment_session(payment_session: open_session) rescue nil
          end
        end

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
        customer_email = order.email.presence || (order.respond_to?(:customer) ? order.customer&.email : nil)
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

      def update_payment_session(payment_session:, amount: nil, external_data: {})
        return payment_session unless payment_session.pending?

        if amount.present? && amount.to_d != payment_session.amount.to_d
          new_total = amount.to_d
          amount_in_paise = (new_total * 100).to_i
          order = payment_session.owner

          razorpay_order = client.order.create(
            amount: amount_in_paise,
            currency: payment_session.currency,
            receipt: order&.number || payment_session.id.to_s,
            notes: {
              spree_order_id: order&.id,
              spree_order_number: order&.number
            }
          )

          new_data = (payment_session.external_data || {}).merge(
            'razorpay_order_id' => razorpay_order.id,
            'amount_in_paise' => amount_in_paise
          )

          payment_session.update!(
            amount: new_total,
            external_id: razorpay_order.id,
            external_data: new_data
          )
        end

        payment_session
      rescue StandardError => e
        Rails.logger.warn("[SpreeRazorpay] update_payment_session error: #{e.message}")
        payment_session
      end

      def cancel_payment_session(payment_session:)
        payment_session.cancel if payment_session.can_cancel?
        payment_session
      end

      def complete_payment_session(payment_session:, params: {})
        # Idempotency guard: if the session is already completed, return immediately without re-settling
        return payment_session if payment_session.completed?
        return payment_session if payment_session.failed? || payment_session.canceled?

        raw_ext = params[:external_data] || params['external_data'] || {}
        ext = raw_ext.respond_to?(:to_h) ? raw_ext.to_h.with_indifferent_access : {}
        razorpay_payment_id = params[:razorpay_payment_id] || params['razorpay_payment_id'] || ext[:razorpay_payment_id]
        razorpay_signature = params[:razorpay_signature] || params['razorpay_signature'] || ext[:razorpay_signature]

        if razorpay_payment_id.blank? || razorpay_signature.blank?
          Rails.logger.warn("[SpreeRazorpay] Incomplete payment params for session #{payment_session.id}")
          payment_session.fail if payment_session.can_fail?
          return payment_session
        end

        generated_signature = OpenSSL::HMAC.hexdigest(
          'sha256',
          preferred_key_secret.to_s,
          "#{payment_session.external_id}|#{razorpay_payment_id}"
        )

        unless ActiveSupport::SecurityUtils.secure_compare(generated_signature, razorpay_signature.to_s)
          Rails.logger.error("[SpreeRazorpay] Signature mismatch for session #{payment_session.id}")
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
        payment_session.complete if payment_session.can_complete?
        payment_session
      rescue StandardError => e
        Rails.logger.error("[SpreeRazorpay] Exception in complete_payment_session: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
        payment_session.fail if payment_session.can_fail?
        payment_session
      end
    end
  end
end
