# frozen_string_literal: true

require 'rails/generators'

module SpreeRazorpay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Installs Spree Razorpay and configures the payment gateway in Spree Admin'

      class_option :key_id, type: :string, desc: 'Razorpay Key ID (e.g. rzp_test_...)'
      class_option :key_secret, type: :string, desc: 'Razorpay Key Secret'
      class_option :name, type: :string, default: 'Razorpay', desc: 'Payment method display name'
      class_option :auto_run_seeds, type: :boolean, default: true, desc: 'Auto-configure payment method in Spree Admin'

      def run_seeds
        if options[:auto_run_seeds]
          say_status :configuring, 'Setting up Razorpay Gateway in Spree Admin...', :green
          ENV['RAZORPAY_KEY_ID'] = options[:key_id] if options[:key_id].present?
          ENV['RAZORPAY_KEY_SECRET'] = options[:key_secret] if options[:key_secret].present?
          ENV['RAZORPAY_NAME'] = options[:name] if options[:name].present?

          rake 'spree_razorpay:seeds'
        else
          say_status :skipped, 'Skipping payment gateway creation. Run `bin/rails spree_razorpay:install` anytime to configure.', :yellow
        end
      end
    end
  end
end
