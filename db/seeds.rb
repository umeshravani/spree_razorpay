# frozen_string_literal: true

stores = Spree::Store.all.presence || [Spree::Store.default]

key_id = ENV['RAZORPAY_KEY_ID'].presence || 'rzp_test_placeholder_key_id'
key_secret = ENV['RAZORPAY_KEY_SECRET'].presence || 'placeholder_secret'
name = ENV['RAZORPAY_NAME'].presence || 'Razorpay'
auto_capture = ENV['RAZORPAY_AUTO_CAPTURE'] != 'false'

stores.each do |store|
  next unless store

  gateway = SpreeRazorpay::Gateway.find_or_initialize_by(
    type: 'SpreeRazorpay::Gateway',
    store: store
  )

  gateway.name = name if gateway.new_record? || gateway.name.blank?
  gateway.active = true
  gateway.storefront_visible = true if gateway.respond_to?(:storefront_visible=)
  gateway.preferred_key_id = key_id if gateway.preferred_key_id.blank? || ENV['RAZORPAY_KEY_ID'].present?
  gateway.preferred_key_secret = key_secret if gateway.preferred_key_secret.blank? || ENV['RAZORPAY_KEY_SECRET'].present?
  gateway.preferred_auto_capture = auto_capture

  if gateway.save
    puts "[SpreeRazorpay] ✓ Successfully configured Payment Method '#{gateway.name}' (ID: #{gateway.id}) for Store '#{store.name}'."
    puts "                Key ID: #{gateway.preferred_key_id}"
    puts "                Active: #{gateway.active?}, Storefront Visible: #{gateway.respond_to?(:storefront_visible?) ? gateway.storefront_visible? : true}, Auto-Capture: #{gateway.preferred_auto_capture}"
  else
    puts "[SpreeRazorpay] ✗ Failed to save Razorpay gateway for store '#{store.name}': #{gateway.errors.full_messages.join(', ')}"
  end
end
