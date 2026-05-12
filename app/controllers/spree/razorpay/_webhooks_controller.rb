module Spree
  class RazorpayWebhooksController < ActionController::API
    skip_before_action :verify_authenticity_token, raise: false

    # Handles asynchronous background webhooks directly from Razorpay's servers
    def create
      payload = request.body.read
      signature = request.headers['X-Razorpay-Signature'] || request.headers['HTTP_X_RAZORPAY_SIGNATURE']
      
      gateway = Spree::Gateway::RazorpayGateway.active.first
      return head :not_found unless gateway && gateway.preferred_webhook_secret.present?

      begin
        # 1. Use the gateway's parser to verify signature and map the action
        parsed_event = gateway.parse_webhook_event(payload, { 'HTTP_X_RAZORPAY_SIGNATURE' => signature })
        
        # If it's an event we don't care about, acknowledge and return
        return head :ok unless parsed_event

        # 2. Extract Data
        payment_session = parsed_event[:payment_session]
        action = parsed_event[:action]
        
        event_data = JSON.parse(payload)
        metadata = event_data.dig('payload', 'payment', 'entity') || {}

        # 3. Trigger the Core Spree 5.5 Webhook Handler Service
        Spree::Payments::HandleWebhook.call(
          payment_method: gateway,
          action: action,
          payment_session: payment_session,
          metadata: metadata
        )

      rescue Spree::PaymentMethod::WebhookSignatureError => e
        Rails.logger.error("Razorpay Webhook Verification Failed: #{e.message}")
        return head :unauthorized
      rescue StandardError => e
        Rails.logger.error("Razorpay Webhook Processing Error: #{e.message}")
        return head :unprocessable_entity
      end

      head :ok
    end

    # Handles synchronous frontend verification from Next.js Storefront
    def verify
      razorpay_order_id = params[:razorpay_order_id]
      razorpay_payment_id = params[:razorpay_payment_id]
      razorpay_signature = params[:razorpay_signature]

      session = Spree::PaymentSession.find_by(external_id: razorpay_order_id)
      return head :not_found unless session
      
      gateway = Spree::Gateway::RazorpayGateway.active.first
      return render json: { success: false, error: 'Gateway not configured' }, status: :internal_server_error unless gateway
      gateway.provider 

      begin
        ::Razorpay::Utility.verify_payment_signature(
          razorpay_order_id: razorpay_order_id,
          razorpay_payment_id: razorpay_payment_id,
          razorpay_signature: razorpay_signature
        )
        
        session.external_data ||= {}
        session.external_data['razorpay_payment_id'] = razorpay_payment_id
        session.external_data['razorpay_signature'] = razorpay_signature
        session.save!

        render json: { success: true }
      rescue ::Razorpay::Errors::SignatureVerificationError => e
        Rails.logger.error("Razorpay Frontend Verification Failed: #{e.message}")
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
