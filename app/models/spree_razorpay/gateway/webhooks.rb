# frozen_string_literal: true

require 'openssl'
require 'active_support/security_utils'

module SpreeRazorpay
  class Gateway < ::Spree::Gateway
    module Webhooks
      extend ActiveSupport::Concern

      WEBHOOK_ACTIONS = {
        'payment.captured'   => :captured,
        'order.paid'         => :captured,
        'payment.authorized' => :authorized,
        'payment.failed'     => :failed,
        'refund.processed'   => :refund_succeeded,
        'refund.failed'      => :refund_failed
      }.freeze

      def parse_webhook_event(raw_body, headers)
        signature = headers['HTTP_X_RAZORPAY_SIGNATURE'] || headers['X-Razorpay-Signature']
        raise Spree::PaymentMethod::WebhookSignatureError, 'Missing signature' if signature.blank?
        raise Spree::PaymentMethod::WebhookSignatureError, 'Webhook secret not configured' if preferred_webhook_secret.blank?

        digest = OpenSSL::HMAC.hexdigest('sha256', preferred_webhook_secret.to_s, raw_body.to_s)
        unless ActiveSupport::SecurityUtils.secure_compare(digest, signature.to_s)
          raise Spree::PaymentMethod::WebhookSignatureError, 'Invalid webhook signature'
        end

        data = JSON.parse(raw_body.to_s)
        event_type = data['event']

        # 1. Handle Refund Webhook Events (for requested/async refunds in Spree 6.0.6)
        refund_payload = data.dig('payload', 'refund', 'entity')
        if refund_payload.present?
          refund_id = refund_payload['id']
          if event_type == 'refund.processed'
            return { action: :refund_succeeded, reference: refund_id, metadata: refund_payload }
          elsif event_type == 'refund.failed'
            reason = refund_payload['error_description'] || refund_payload['error_reason'] || 'Refund failed by provider'
            return { action: :refund_failed, reference: refund_id, metadata: { 'reason' => reason } }
          end
        end

        # 2. Handle Payment/Order Webhook Events
        action = WEBHOOK_ACTIONS[event_type]
        return nil unless action

        payload = data.dig('payload', 'payment', 'entity') || data.dig('payload', 'order', 'entity')
        return nil unless payload

        order_id = payload['order_id'] || payload['id']

        session = Spree::PaymentSessions::Razorpay.find_by(
          payment_method: self,
          external_id: order_id
        )

        if session.present?
          if (action == :captured || action == :authorized) && payload['id'].present?
            session.update!(
              external_data: (session.external_data || {}).merge('razorpay_payment_id' => payload['id'])
            )
          end
          return { action: action, payment_session: session }
        end

        # 3. If no payment session found, check for async capture on existing payment
        if action == :captured
          { action: :capture_succeeded, reference: payload['id'], metadata: payload }
        elsif action == :failed
          reason = payload['error_description'] || payload['error_reason'] || 'Payment failed by provider'
          { action: :capture_failed, reference: payload['id'], metadata: { 'reason' => reason } }
        else
          nil
        end
      rescue JSON::ParserError
        raise Spree::PaymentMethod::WebhookSignatureError, 'Malformed webhook payload'
      end
    end
  end
end
