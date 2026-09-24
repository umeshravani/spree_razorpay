# encoding: UTF-8

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_razorpay'
  s.version     = '6.0.0'
  s.authors     = ['Umesh Ravani']
  s.email       = 'umeshravani98@gmail.com'
  s.summary     = 'Razorpay Payment Gateway for Spree Commerce'
  s.description = 'Razorpay payment provider and webhooks for Spree 6'
  s.homepage    = 'https://spreecommerce.org'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.2'

  s.files        = Dir["{app,config,db,lib,vendor}/**/*", "Rakefile", "LICENSE", "README.md"].reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'

  s.add_dependency 'spree_core', '>= 6.0.0.beta1'
  s.add_dependency 'razorpay', '~> 3.0'

end
