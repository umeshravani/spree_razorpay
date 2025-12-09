lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'spree_razorpay_checkout/version'

Gem::Specification.new do |spec|
  spec.name          = 'spree_razorpay_checkout'
  spec.version       = SpreeRazorpayCheckout.version
  spec.platform      = Gem::Platform::RUBY
  spec.summary       = 'Razorpay integration for Spree Commerce 5.2'
  spec.description   = 'Seamless Razorpay checkout integration for Spree Commerce 5.x stores.'
  spec.required_ruby_version = '>= 3.1.2'

  # Author info
  spec.authors       = ['Umesh Ravani']
  spec.email         = ['umeshravani98@gmail.com']
  spec.homepage      = 'https://github.com/umeshravani/spree_razorpay'
  spec.license       = 'BSD-3-Clause'

  # Automatically include most important files
  spec.files = Dir.glob([
    'lib/**/*',
    'app/**/*',
    'config/**/*',
    'db/**/*',
    'public/**/*',
    'README.md',
    'LICENSE.txt'
  ])

  spec.require_paths = ['lib']

  # Gem dependencies
  spec.add_dependency 'razorpay', '~> 3.2'
  
  # CHANGE 1: Depend on spree_core, not the huge 'spree' meta-gem. 
  # This allows the extension to work with ANY frontend (Storefront or Old).
  spec.add_dependency 'spree_core', '>= 5.2'
  
  spec.add_dependency 'spree_extension'

  # Development dependencies
  spec.add_development_dependency 'spree_dev_tools'

  # RubyGems.org metadata (no warnings)
  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'changelog_uri'   => "#{spec.homepage}/blob/main/CHANGELOG.md"
  }
end
