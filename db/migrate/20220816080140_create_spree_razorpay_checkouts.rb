class CreateSpreeRazorpayCheckouts < ActiveRecord::Migration[6.1]
  def change
    unless table_exists?(:spree_razorpay_checkouts)
      create_table :spree_razorpay_checkouts do |t|
        t.references :order, null: true, foreign_key: { to_table: :spree_orders }
        t.string :razorpay_order_id
        t.string :razorpay_payment_id
        t.string :razorpay_signature
        t.string :status
        t.string :payment_method
        t.string :card_id
        t.string :bank
        t.string :wallet
        t.string :vpa
        t.string :email
        t.string :contact

        t.timestamps
      end
    end

    add_index :spree_razorpay_checkouts, :razorpay_order_id unless index_exists?(:spree_razorpay_checkouts, :razorpay_order_id)
    add_index :spree_razorpay_checkouts, :razorpay_payment_id unless index_exists?(:spree_razorpay_checkouts, :razorpay_payment_id)
  end
end
