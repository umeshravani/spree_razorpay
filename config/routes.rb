Spree::Core::Engine.add_routes do
  
  namespace :razorpay do
    post :webhooks, to: 'webhooks#create'
    post :verify, to: 'webhooks#verify'
  end
end
