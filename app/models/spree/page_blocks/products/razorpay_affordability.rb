module Spree
  module PageBlocks
    module Products
      class RazorpayAffordability < Spree::PageBlock
        # Key / fallback
        preference :merchant_key_id, :string
        preference :fallback_amount, :integer, default: 50000

        # Appearance & Color (header/theme + heading + content + discount + link/button + footer + darkmode)
        preference :theme_color, :string, default: '#800080' # header theme color
        preference :heading_color, :string, default: '#000000'
        preference :heading_font_size, :integer, default: 14 # px

        preference :content_background_color, :string, default: '#ffffff'
        preference :content_color, :string, default: '#000000'
        preference :content_font_size, :integer, default: 13 # px

        preference :discount_color, :string, default: '#e60099'

        # link/button
        preference :link_button, :boolean, default: true
        preference :link_color, :string, default: '#000000'
        preference :link_font_size, :integer, default: 12 # px

        # footer
        preference :footer_color, :string, default: '#000000'
        preference :footer_font_size, :integer, default: 12 # px
        preference :footer_dark_logo, :boolean, default: false

        # dark mode
        preference :is_dark_mode, :boolean, default: false

        # Widget settings toggles
        preference :offers_enabled, :boolean, default: true
        preference :emi_enabled, :boolean, default: true
        preference :cardless_emi_enabled, :boolean, default: true
        preference :paylater_enabled, :boolean, default: true

        # expose names & metadata for admin (optional helper methods)
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
            Rails.logger.info "  Available check: #{is_available}"
            unless is_available
              Rails.logger.warn "  Block marked as not available, but rendering anyway"
            end
          end

          begin
            Rails.logger.info "  Rendering partial: spree/page_blocks/products/razorpay_affordability/razorpay_affordability"
            result = view_context.render partial: 'spree/page_blocks/products/razorpay_affordability/razorpay_affordability',
                                         locals: locals.merge(block: self, page_block: self)
            Rails.logger.info " Render successful, output length: #{result.to_s.length}"
            result
          rescue ActionView::MissingTemplate => e
            Rails.logger.error "  Missing template: #{e.message}"
            ''
          rescue => e
            Rails.logger.error "  Error rendering Razorpay Affordability block: #{e.message}"
            "<div class='razorpay-affordability-error'>Error loading Razorpay Affordability Widget</div>".html_safe
          end
        end
      end
    end
  end
end
