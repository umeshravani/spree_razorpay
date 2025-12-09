module Spree
    module ProductsControllerDecorator
      def self.prepended(base)
        base.before_action :force_razorpay_view_priority
      end
  
      private
  
      def force_razorpay_view_priority
        plugin_theme_path = SpreeRazorpayCheckout::Engine.root.join('app', 'views', 'themes', 'default')
        prepend_view_path(plugin_theme_path)

      end
    end
  end
  
  ::Spree::ProductsController.prepend(Spree::ProductsControllerDecorator)
