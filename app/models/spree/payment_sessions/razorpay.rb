module Spree
  module PaymentSessions
    class Razorpay < Spree::PaymentSession

      def client_key
        external_data['client_key']
      end
      
      def razorpay_order_id
        external_id
      end
    end
  end
end
