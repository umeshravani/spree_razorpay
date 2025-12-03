# Only run this if Sprockets is loaded (Spree 4.x / 5.0)
if Rails.configuration.respond_to?(:assets) && defined?(Sprockets)
  Rails.application.config.assets.precompile += %w[
  payment_icons/razorpay_logo_dark.svg
  payment_icons/razorpay_logo_light.svg
  payment_icons/razorpay.svg
  payment_icons/razorpaycheckout.svg
  payment_icons/window_modal.svg
]
end
