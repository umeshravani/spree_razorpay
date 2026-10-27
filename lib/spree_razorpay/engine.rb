# frozen_string_literal: true

require 'rails/engine'

module SpreeRazorpay
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'spree_razorpay'

    initializer 'spree_razorpay.inflections', before: :set_autoload_paths do
      Rails.autoloaders.each do |autoloader|
        autoloader.inflector.inflect('spree_razorpay' => 'SpreeRazorpay')
      end
    end

    config.to_prepare do
      unless defined?(::ActiveMerchant::Billing::Response)
        module ::ActiveMerchant
          module Billing
            Response = ::Spree::PaymentResponse
          end
        end
      end

      unless defined?(::Razorpay::Client)
        module ::Razorpay
          class Client
            attr_reader :key_id, :key_secret

            def initialize(key_id, key_secret)
              @key_id = key_id
              @key_secret = key_secret
              ::Razorpay.setup(key_id, key_secret)
            end

            def refund
              ::Razorpay::Refund
            end

            def payment
              ::Razorpay::Payment
            end

            def order
              ::Razorpay::Order
            end
          end
        end
      end
    end

    config.after_initialize do
      Rails.application.config.spree.payment_methods << SpreeRazorpay::Gateway
    end
  end
end
