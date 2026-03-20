module Spree
    module Razorpay
      class WebhooksController < ActionController::API
        skip_before_action :verify_authenticity_token, raise: false
  
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
      end
    end
  end
