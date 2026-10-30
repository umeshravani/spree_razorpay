# frozen_string_literal: true

require 'spree_core'
require 'razorpay'

# Thread-safe extension for Razorpay custom headers to prevent cross-request leakage
module Razorpay
  class << self
    def custom_headers
      Thread.current[:razorpay_custom_headers] || @custom_headers || {}
    end

    def custom_headers=(headers)
      Thread.current[:razorpay_custom_headers] = headers
    end
  end
end

module SpreeRazorpay
  # configuration can go here if needed
end

require 'spree_razorpay/engine'
