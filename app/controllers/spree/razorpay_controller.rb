module Spree
  class RazorpayController < StoreController
    skip_before_action :verify_authenticity_token

    include Spree::RazorPay

    # Step 1: Create Razorpay Order
    def create_order
      order = Spree::Order.find_by(id: params[:order_id])
      order&.reload

      return render json: { success: false, error: 'Order not found' }, status: :not_found unless order

      if order.outstanding_balance <= 0
        return render json: { success: false, error: "Order is already paid" }, status: :unprocessable_entity
      end

      razorpay_order_id, amount = ::Razorpay::RpOrder::Api.new.create(order.id)

      if razorpay_order_id.present?
        render json: { success: true, razorpay_order_id: razorpay_order_id, amount: amount }
      else
        render json: { success: false, error: "Failed to create Razorpay order" }, status: :unprocessable_entity
      end
    end

    # Step 2: Handle Response
    def razor_response
      order = Spree::Order.find_by(number: params[:order_id] || params[:order_number])
      unless order
        flash[:error] = "Order not found."
        return redirect_to checkout_state_path(:payment)
      end

      unless valid_signature?
        flash[:error] = "Payment signature verification failed."
        return redirect_to checkout_state_path(order.state)
      end

      begin
        razorpay_payment = gateway.verify_and_capture_razorpay_payment(order, razorpay_payment_id)
        spree_payment = order.razor_payment(razorpay_payment, payment_method, params[:razorpay_signature])

        if razorpay_payment.status == 'captured'
          spree_payment.complete!
        elsif razorpay_payment.status == 'authorized'
          spree_payment.pend!
        end
        while !order.completed?
          order.next!
        end
        redirect_to completion_route

      rescue StandardError => e
        Rails.logger.error("Razorpay Error: #{e.message}\n#{e.backtrace.join("\n")}")
        flash[:error] = "Payment Error: #{e.message}"
        redirect_to checkout_state_path(order.state)
      end
    end

    private

    def razorpay_payment_id
      params[:razorpay_payment_id] || params.dig(:payment_source, payment_method.id.to_s, :razorpay_payment_id)
    end

    def razorpay_payment
      @razorpay_payment ||= Razorpay::Payment.fetch(razorpay_payment_id)
    end

    def valid_signature?
      p_id = payment_method.id.to_s
      r_order_id = params[:razorpay_order_id] || params.dig(:payment_source, p_id, :razorpay_order_id)
      r_pay_id   = razorpay_payment_id
      r_sig      = params[:razorpay_signature] || params.dig(:payment_source, p_id, :razorpay_signature)

      Razorpay::Utility.verify_payment_signature(
        razorpay_order_id: r_order_id,
        razorpay_payment_id: r_pay_id,
        razorpay_signature: r_sig
      )
    rescue Razorpay::Error => e
      Rails.logger.error("Razorpay signature verification failed: #{e.message}")
      false
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find_by(id: params[:payment_method_id]) || Spree::PaymentMethod.find_by(type: 'Spree::Gateway::RazorpayGateway')
    end

    def gateway
      payment_method
    end

    def order
      @order ||= Spree::Order.find_by(number: params[:order_id] || params[:order_number])
    end
    
    def completion_route
      token = order.respond_to?(:guest_token) ? order.guest_token : order.token

      if token.present?
        "/checkout/#{token}/complete"
      else
        spree.order_path(order)
      end
    end
  end
end
