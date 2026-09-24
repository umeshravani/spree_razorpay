# frozen_string_literal: true

namespace :spree_razorpay do
  desc 'Seed or configure Razorpay Payment Gateway in Spree Admin'
  task seeds: :environment do
    seed_file = File.expand_path('../../db/seeds.rb', __dir__)
    if File.exist?(seed_file)
      load(seed_file)
    else
      puts "Seed file not found at #{seed_file}"
    end
  end

  desc 'Install Spree Razorpay plugin and configure payment gateway in Spree Admin'
  task install: :seeds

  desc 'Interactive CLI setup for Razorpay credentials in Spree Admin'
  task setup: :environment do
    store = Spree::Store.default
    puts "\n======================================================="
    puts "       Spree Razorpay Payment Gateway Setup            "
    puts "=======================================================\n"

    print "Enter Razorpay Key ID (e.g. rzp_test_...): "
    key_id = $stdin.gets.to_s.strip
    key_id = 'rzp_test_placeholder_key_id' if key_id.blank?

    print "Enter Razorpay Key Secret: "
    key_secret = $stdin.gets.to_s.strip
    key_secret = 'placeholder_secret' if key_secret.blank?

    print "Enter Payment Method Display Name [Razorpay]: "
    name = $stdin.gets.to_s.strip
    name = 'Razorpay' if name.blank?

    gateway = SpreeRazorpay::Gateway.find_or_initialize_by(
      type: 'SpreeRazorpay::Gateway',
      store: store
    )
    gateway.name = name
    gateway.active = true
    gateway.storefront_visible = true if gateway.respond_to?(:storefront_visible=)
    gateway.preferred_key_id = key_id
    gateway.preferred_key_secret = key_secret
    gateway.preferred_auto_capture = true

    if gateway.save
      puts "\n✓ Razorpay Gateway configured successfully!"
      puts "  - Store: #{store.name}"
      puts "  - Method ID: #{gateway.id}"
      puts "  - Name: #{gateway.name}"
      puts "  - Key ID: #{gateway.preferred_key_id}"
      puts "  - Active: #{gateway.active}"
    else
      puts "\n✗ Error saving Razorpay gateway: #{gateway.errors.full_messages.join(', ')}"
    end
  end
end
