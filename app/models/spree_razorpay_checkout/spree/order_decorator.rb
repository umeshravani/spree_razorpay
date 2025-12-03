module SpreeRazorpayCheckout
  module Spree
    module OrderDecorator
      
      def inr_amt_in_paise
        payments.reload 

        prepaid_amount = payments.select do |p| 
          valid_state = %w[checkout pending processing completed].include?(p.state)
          
          not_razorpay = !p.source_type.to_s.include?('RazorpayCheckout') && 
                         !p.payment_method&.type.to_s.include?('RazorpayGateway')

          valid_state && not_razorpay
        end.sum(&:amount)

        amount_needed = total - prepaid_amount

        Rails.logger.info "Razorpay Calc: Total=#{total}, Prepaid=#{prepaid_amount}, Needed=#{amount_needed}"

        return 0 if amount_needed <= 0

        (amount_needed.to_f * 100).to_i
      end

      def razor_payment(payment_object, payment_method, razorpay_signature)

        amount_to_charge = (inr_amt_in_paise / 100.0)

        amount_to_charge = total if amount_to_charge <= 0

        source = ::Spree::RazorpayCheckout.create!(
          order_id: id,
          razorpay_payment_id: payment_object.id,
          razorpay_order_id: payment_object.order_id,
          razorpay_signature: razorpay_signature,
          status: payment_object.status,
          payment_method: payment_object.method,
          card_id: payment_object.card_id,
          bank: payment_object.bank,
          wallet: payment_object.wallet,
          vpa: payment_object.vpa,
          email: payment_object.email,
          contact: payment_object.contact
        )

        payment = payments.create!(
          source: source,
          payment_method: payment_method,
          amount: amount_to_charge,
          response_code: payment_object.id
        )

        payment
      end

      ::Spree::Order.prepend SpreeRazorpayCheckout::Spree::OrderDecorator
    end
  end
end
