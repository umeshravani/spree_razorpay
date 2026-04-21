module SpreeRazorpayCheckout
  VERSION = '0.3.0'.freeze

  module_function

  # Returns the version of the currently loaded SpreeRazorpay as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION
  end
end
