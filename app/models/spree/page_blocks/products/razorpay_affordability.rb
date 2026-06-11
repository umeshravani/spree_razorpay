module Spree
  module PageBlocks
    module Products
      # Dynamically inherit so Zeitwerk finds the constant without crashing
      class RazorpayAffordability < (defined?(Spree::PageBlock) ? Spree::PageBlock : Object)
        
        # Only evaluate Spree-specific logic if the parent is actually a PageBlock
        if defined?(Spree::PageBlock)
          preference :merchant_key_id, :string
          preference :fallback_amount, :integer, default: 50000
          preference :theme_color, :string, default: '#800080'
          preference :heading_color, :string, default: '#000000'
          preference :heading_font_size, :integer, default: 14
          preference :content_background_color, :string, default: '#ffffff'
          preference :content_color, :string, default: '#000000'
          preference :content_font_size, :integer, default: 13
          preference :discount_color, :string, default: '#e60099'
          preference :link_button, :boolean, default: true
          preference :link_color, :string, default: '#000000'
          preference :link_font_size, :integer, default: 12
          preference :footer_color, :string, default: '#000000'
          preference :footer_font_size, :integer, default: 12
          preference :footer_dark_logo, :boolean, default: false
          preference :is_dark_mode, :boolean, default: false
          preference :offers_enabled, :boolean, default: true
          preference :emi_enabled, :boolean, default: true
          preference :cardless_emi_enabled, :boolean, default: true
          preference :paylater_enabled, :boolean, default: true

          def self.block_name
            "Razorpay Affordability Widget"
          end

          def self.display_name
            "Razorpay Affordability"
          end

          def icon_name
            "hexagon-letter-r"
          end

          def render(view_context, locals = {})
            Rails.logger.info "🎯 RazorpayAffordability#render called for block ID: #{id}"
            if respond_to?(:available?, true)
              is_available = available?(locals)
              unless is_available
                Rails.logger.warn "  Block marked as not available, but rendering anyway"
              end
            end

            begin
              result = view_context.render partial: 'spree/page_blocks/products/razorpay_affordability/razorpay_affordability',
                                           locals: locals.merge(block: self, page_block: self)
              result
            rescue ActionView::MissingTemplate => e
              ''
            rescue => e
              "<div class='razorpay-affordability-error'>Error loading Razorpay Affordability Widget</div>".html_safe
            end
          end
        end
      end
    end
  end
end
