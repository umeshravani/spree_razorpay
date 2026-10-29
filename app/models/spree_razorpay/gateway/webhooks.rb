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
        'payment.failed'     => :failed
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
        action = WEBHOOK_ACTIONS[event_type]
        return nil unless action

        payload = data.dig('payload', 'payment', 'entity') || data.dig('payload', 'order', 'entity')
        return nil unless payload

        order_id = payload['order_id'] || payload['id']

        session = Spree::PaymentSessions::Razorpay.find_by(
          payment_method: self,
          external_id: order_id
        )
        return nil unless session

        if (action == :captured || action == :authorized) && payload['id'].present?
          session.update!(
            external_data: (session.external_data || {}).merge('razorpay_payment_id' => payload['id'])
          )
        end

        { action: action, payment_session: session }
      rescue JSON::ParserError
        raise Spree::PaymentMethod::WebhookSignatureError, 'Malformed webhook payload'
      end
    end
  end
end
