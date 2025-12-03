module Spree
  class RazorpayCheckout < Spree::Base
    self.table_name = 'spree_razorpay_checkouts'

    belongs_to :order, class_name: 'Spree::Order', optional: true

    def name
      "Razorpay Secure (UPI, Wallets, Cards & Netbanking)"
    end

    def method_type
      "razorpay"
    end

    def payment_id
      self.razorpay_payment_id
    end

    def order_id
      self.razorpay_order_id
    end
  end
end
