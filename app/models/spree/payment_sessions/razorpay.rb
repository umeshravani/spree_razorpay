module Spree
  module PaymentSessions
    class Razorpay < Spree::PaymentSession
      # Helper method to expose the Razorpay Order ID to the frontend API
      def razorpay_order_id
        external_id
      end
    end
  end
end
