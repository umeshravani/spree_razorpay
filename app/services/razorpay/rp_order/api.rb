module Razorpay
  module RpOrder
    class Api < Razorpay::Base
      attr_reader :order

      def create(order_id)
        @order = Spree::Order.find_by(id: order_id)
        raise "Order not found" unless order

        Razorpay.headers = {
          "Content-Type" => "application/json",
          "Accept"       => "application/json"
        }

        params = order_create_params
        Rails.logger.info "Razorpay::Order.create Params: #{params.inspect}"
        
        razorpay_order = Razorpay::Order.create(params.to_json)
        
        if razorpay_order.try(:id).present?
          log_order_in_db(razorpay_order.id)
          return [razorpay_order.id, params[:amount]]
        end
        ['', 0]
      rescue StandardError => e
        Rails.logger.error("Razorpay Order create failed: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        ['', 0]
      end

      private

      def order_create_params
        amt = order.inr_amt_in_paise
        {
          amount: amt.to_i, 
          currency: (order.currency || 'INR').to_s,
          receipt: order.number.to_s,
          payment_capture: 1
        }
      end

      def log_order_in_db(rzp_order_id)
        Spree::RazorpayCheckout.create!(
          order_id: order.id,
          razorpay_order_id: rzp_order_id,
          status: 'created'
        )
      rescue StandardError => e
        Rails.logger.error("Failed to log Razorpay Order in DB: #{e.message}")
      end
    end
  end
end
