module SpreeRazorpayCheckout
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_razorpay_checkout'

    require 'spree_razorpay_checkout/configuration'

    config.generators do |g|
      g.test_framework :rspec
    end

    config.after_initialize do |_app|
      SpreeRazorpayCheckout::Config = SpreeRazorpayCheckout::Configuration.new
    end

    def self.activate
      # Load all decorators from the plugin's app directory
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Register Razorpay payment method
    config.after_initialize do |app|
      app.config.spree.payment_methods ||= []
      app.config.spree.payment_methods << ::Spree::Gateway::RazorpayGateway
    end

    # Register custom PDP Page Block
    config.to_prepare do
      # 1. Force load the class so 'defined?' becomes true
      #    To Ensure the file exists at: app/models/spree/page_blocks/products/razorpay_affordability.rb
      require_dependency 'spree/page_blocks/products/razorpay_affordability' rescue nil

      # 2. Register the block unconditionally if Spree::PageBlock exists
      if defined?(Spree::PageBlock)
        Spree::PageBlock.register_block(Spree::PageBlocks::Products::RazorpayAffordability)
      end
      
      # 3. Activate decorators
      SpreeRazorpayCheckout::Engine.activate
    end
  end
end
