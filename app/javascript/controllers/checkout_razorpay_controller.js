import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    paymentMethodId: String,
    keyId: String,
    orderId: String,
    amount: Number,
    currency: String,
    merchantName: String,
    merchantDesc: String,
    themeColor: String,
    userName: String,
    userEmail: String,
    userContact: String
  }

  static targets = [
    'paymentId',
    'orderId',
    'signature'
  ]

  connect() {
    this.form = document.querySelector("#checkout_form_payment")
    this.submitBtn = document.getElementById("checkout-payment-submit")
    
    // Bind to the form submit event, NOT the button click! 
    // This perfectly intercepts Spree 5.3's native validation flows.
    this.submitHandler = this.submit.bind(this)
    this.form.addEventListener('submit', this.submitHandler)
  }

  disconnect() {
    if (this.form) {
      this.form.removeEventListener('submit', this.submitHandler)
    }
  }

  submit(e) {
    // Check if Razorpay is the currently selected radio button
    const selectedRadio = document.querySelector('input[name="order[payments_attributes][][payment_method_id]"]:checked');
    const isRazorpay = selectedRadio && selectedRadio.value === this.paymentMethodIdValue;
    
    if (!isRazorpay) return; // If it's a different gateway, let Spree handle it normally

    // If we already have the Razorpay signature populated, let the form submit natively to the backend!
    if (this.paymentIdTarget.value && this.signatureTarget.value) {
      return true; 
    }

    // Otherwise, STOP the form submission and open Razorpay
    e.preventDefault();
    e.stopImmediatePropagation();
    
    this.setLoading(true);

    const options = {
      key: this.keyIdValue,
      order_id: this.orderIdValue,
      amount: this.amountValue,
      currency: this.currencyValue,
      name: this.merchantNameValue,
      description: this.merchantDescValue,
      handler: this.handleSuccess.bind(this),
      modal: {
        ondismiss: this.handleDismiss.bind(this)
      },
      prefill: {
        name: this.userNameValue,
        email: this.userEmailValue,
        contact: this.userContactValue
      },
      theme: {
        color: this.themeColorValue
      }
    };

    const rzp = new window.Razorpay(options);
    rzp.open();
  }

  handleSuccess(response) {
    // 1. Populate the hidden fields with the secure response
    this.paymentIdTarget.value = response.razorpay_payment_id;
    this.orderIdTarget.value = response.razorpay_order_id;
    this.signatureTarget.value = response.razorpay_signature;

    // 2. Submit the form natively to Spree's backend!
    // requestSubmit() ensures Turbo and Spree's event listeners fire correctly
    this.form.requestSubmit(); 
  }

  handleDismiss() {
    this.setLoading(false);
  }

  setLoading(isLoading) {
    if (isLoading) {
      this.submitBtn.disabled = true;
      this.submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Processing...';
    } else {
      this.submitBtn.disabled = false;
      // Reset Spree button text depending on what it usually says
      this.submitBtn.innerHTML = 'Save and Continue'; 
    }
  }
}
