module Spree
  module Razorpay
    class WebhooksController < ActionController::API
      skip_before_action :verify_authenticity_token, raise: false

      # Handles asynchronous background webhooks directly from Razorpay's servers
      def create
        payload = request.body.read
        signature = request.headers['X-Razorpay-Signature']
        
        gateway = Spree::Gateway::RazorpayGateway.active.first
        return head :not_found unless gateway && gateway.preferred_webhook_secret.present?

        begin
          ::Razorpay::Utility.verify_webhook_signature(
            payload, 
            signature, 
            gateway.preferred_webhook_secret
          )
        rescue ::Razorpay::Errors::SignatureVerificationError => e
          Rails.logger.error("Razorpay Webhook Verification Failed: #{e.message}")
          return head :unauthorized
        end

        event = JSON.parse(payload)

        # Listen for 'payment.authorized' which fires immediately after OTP!
        if ['order.paid', 'payment.captured', 'payment.authorized'].include?(event['event'])
          ::SpreeRazorpayCheckout::HandleWebhookEventJob.perform_later(event)
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
        
        # Initialize the Razorpay gem with your active API keys
        gateway = Spree::Gateway::RazorpayGateway.active.first
        return render json: { success: false, error: 'Gateway not configured' }, status: :internal_server_error unless gateway
        gateway.provider 

        begin
          # 1. Verify the signature securely on the server
          ::Razorpay::Utility.verify_payment_signature(
            razorpay_order_id: razorpay_order_id,
            razorpay_payment_id: razorpay_payment_id,
            razorpay_signature: razorpay_signature
          )
          
          # 2. Inject the signatures into the session's external_data
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
end
