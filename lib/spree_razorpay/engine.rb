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

    config.after_initialize do
      Rails.application.config.spree.payment_methods << SpreeRazorpay::Gateway
    end
  end
end
