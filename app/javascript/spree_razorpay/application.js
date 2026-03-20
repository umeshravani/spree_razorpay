import { Application } from '@hotwired/stimulus'
import CheckoutRazorpayController from './controllers/checkout_razorpay_controller'

let application;
if (typeof window.Stimulus === "undefined") {
  application = Application.start()
  window.Stimulus = application
} else {
  application = window.Stimulus
}

application.register('checkout-razorpay', CheckoutRazorpayController)
