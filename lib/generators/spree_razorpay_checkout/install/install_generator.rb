module SpreeRazorpayCheckout
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      class_option :migrate, type: :boolean, default: true

      def add_migrations
        run 'bin/rails railties:install:migrations FROM=spree_razorpay_checkout'
      end

      def run_migrations
        if options[:migrate]
          run 'bin/rails db:migrate'
        else
          say_status :skip, "Skipped running migrations. You can run them later with `bin/rails db:migrate`.", :yellow
        end
      end

      def add_razorpay_widget_block
        say_status :spree_razorpay_checkout, "Checking for CMS Product Details section to append Affordability widget...", :green
        require Rails.root.join("config/environment")
        
        # Shopify-Grade Fallback Check: Only execute if Page Builder models are present in runtime
        if Object.const_defined?("Spree::PageSection") && Spree::PageSection.respond_to?(:where)
          ::Spree::PageSection
            .where(type: "Spree::PageSections::ProductDetails")
            .find_each do |section|
              next if section.blocks.exists?(type: "Spree::PageBlocks::Products::RazorpayAffordability")
              
              section.blocks.create!(
                type: "Spree::PageBlocks::Products::RazorpayAffordability",
                position: section.blocks.maximum(:position).to_i + 1
              )
              say_status :created, "Added Razorpay block to section: #{section.name}", :green
            end
        else
          say_status :skipping, "CMS Layout core engines not active in this app context. Skipping widget layout injection.", :blue
        end
      end
    end
  end
end
