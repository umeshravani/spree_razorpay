Spree::Core::Engine.add_routes do
  post '/razorpay/webhooks', to: 'razorpay_webhooks#create'
  post '/razorpay/verify',   to: 'razorpay_webhooks#verify'
end
