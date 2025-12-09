module Spree
    module PageSections
      module ProductDetailsDecorator
        def default_blocks
          super + [Spree::PageBlocks::Products::RazorpayAffordability.new]
        end
  
        def available_blocks_to_add
          super + [Spree::PageBlocks::Products::RazorpayAffordability]
        end
      end
    end
  end
  
  Spree::PageSections::ProductDetails.prepend(
    Spree::PageSections::ProductDetailsDecorator
  )
