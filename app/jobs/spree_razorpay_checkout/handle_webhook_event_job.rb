module SpreeRazorpayCheckout
    class HandleWebhookEventJob < ActiveJob::Base
      queue_as :default
  
      def perform(event)
        payload = event['payload']
        payment_entity = payload.dig('payment', 'entity') || payload.dig('order', 'entity')
        
        # Razorpay might send the ID in slightly different places depending on the event
        razorpay_order_id = payment_entity['order_id'] || payload.dig('order', 'entity', 'id')
        razorpay_payment_id = payment_entity['id'] 
        
        checkout_record = Spree::RazorpayCheckout.find_by(razorpay_order_id: razorpay_order_id)
        return unless checkout_record
        
        order = checkout_record.order
        return if order.completed? || order.canceled?
  
        gateway = Spree::Gateway::RazorpayGateway.active.first
        return unless gateway
  
        order.with_lock do
          # 1. Capture the abandoned payment via API
          begin
            rzp_payment = ::Razorpay::Payment.fetch(razorpay_payment_id)
            if rzp_payment.status == 'authorized'
              amount_in_cents = (order.total_minus_store_credits.to_f * 100).to_i
              rzp_payment.capture({ amount: amount_in_cents })
            end
          rescue StandardError => e
            Rails.logger.error("Webhook Razorpay Capture Failed: #{e.message}")
            return
          end
  
          checkout_record.update!(
            razorpay_payment_id: razorpay_payment_id,
            status: 'captured'
          )
  
          # 2. Create the Spree::Payment record natively
          payment = order.payments.find_or_create_by!(
            response_code: razorpay_payment_id,
            payment_method_id: gateway.id
          ) do |p|
            p.amount = order.total
            p.source = checkout_record
            p.state = 'checkout'
          end
  
          # 3. Mark the payment as completed
          payment.process! if payment.checkout?
          payment.complete! if payment.pending? || payment.processing?
  
          # Tell Spree to recalculate the payment state
          order.updater.update_payment_state
          
          # Loop through the checkout steps (Payment -> Confirm -> Complete)
          until order.completed? || order.state == 'complete'
            order.next!
          end
          
        end
      end
    end
  end
