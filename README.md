# Spree Razorpay (Spree 6 / Next.js Storefront)

This plugin integrates **Razorpay** as a payment gateway in Spree 6, supporting UPI, Credit/Debit Cards, NetBanking, and Wallets using Razorpay Standard Checkout in the official Spree 6 Next.js Storefront.

<img width="1202" height="1004" alt="Delhivery Checkout Page Spree 6" src="https://github.com/user-attachments/assets/315b41c9-962e-4bc6-a2fc-e230c7e55d1a" />

---

## Features

- **Spree 6 Native Payment Sessions**: Fully integrated with the API V3 payment sessions architecture (`/payment_sessions`).
- **Razorpay Standard Modal**: Seamless modal popup using Razorpay's `checkout.js` SDK.
- **Auto Prefill**: Prefills customer name, email, and mobile number from the checkout shipping address.
- **Cryptographic Signature Verification**: Verifies `razorpay_payment_id`, `razorpay_order_id`, and `razorpay_signature` upon payment completion before finalizing the order.
- **Currency Support**: Fully supports INR and international currencies enabled on your Razorpay account.

---

## Backend Installation & Setup

### 1. Add Plugin to Gemfile

In `server/Gemfile`:
```ruby
gem 'spree_razorpay', path: 'plugins/razorpay'
```

Run bundle install:
```bash
bundle install
```

### 2. Auto-Install / Seed Razorpay in Spree Admin

You can automatically create and configure the **Razorpay Payment Method** in Spree Admin with a single console command:

```bash
bin/rails spree_razorpay:install
```

*(Or pass your credentials directly via environment variables or generator flags):*

```bash
# Via rake task with credentials:
RAZORPAY_KEY_ID="rzp_test_..." RAZORPAY_KEY_SECRET="your_secret" bin/rails spree_razorpay:install

# Or via Rails generator:
bin/rails generate spree_razorpay:install --key-id="rzp_test_..." --key-secret="your_secret"

# Or interactive CLI wizard:
bin/rails spree_razorpay:setup
```

This automatically sets:
- **Provider**: `SpreeRazorpay::Gateway`
- **Name**: `Razorpay`
- **Active**: `true`
- **Storefront Visible**: `true`
- **Auto Capture**: `true`

---

### 3. Manual Configuration in Spree Admin (Alternative)

If you prefer to configure manually via the Spree Admin UI:

1. Log in to your Spree Admin Dashboard (`/admin` or `http://localhost:5173`).
2. Navigate to **Settings > Payments > New Payment Method**.
3. Fill in the payment method settings:
   - **Provider**: Select `SpreeRazorpay::Gateway`
   - **Name**: `Razorpay` (or `Credit/Debit Card, UPI, NetBanking`)
   - **Active**: `Yes`
   - **Storefront Visible**: `Yes`
4. Under Gateway Preferences:
   - **Key ID**: Your Razorpay Key ID (starts with `rzp_test_` or `rzp_live_`)
   - **Key Secret**: Your Razorpay Key Secret
   - **Auto Capture**: Checked (`Yes`)
5. Save the payment method.


---

## Storefront (Next.js) Integration

To integrate Razorpay into the Spree 6 Next.js storefront (`apps/storefront`), refer to the dedicated, step-by-step implementation guide:

👉 **[Complete Storefront Implementation Guide](./Storefront_Implementation.md)**

This guide covers:
- Adding the official Razorpay SVG brand badge
- Registering gateway mappings in `payment-gateway.ts`
- Creating the `RazorpayPaymentForm.tsx` modal checkout component
- Mounting in `PaymentSection.tsx`
- Complete end-to-end architecture and sandbox testing details

---

## How It Works Under the Hood

1. **Session Creation**:
   When the user selects Razorpay, `createCheckoutPaymentSession(cart.id, method.id)` sends `POST /api/v3/store/carts/:id/payment_sessions`.
2. **Order Generation in Razorpay**:
   The Spree backend (`SpreeRazorpay::Gateway::PaymentSessions`) contacts the Razorpay API (`POST /v1/orders`) and secures a `razorpay_order_id`. It stores the `key_id`, `order_id`, and `amount_in_paise` in `session.external_data`.
3. **Modal Checkout**:
   When the user clicks "Pay Now", `gatewayHandleRef.current.confirmPayment()` is called. This launches the Razorpay modal checkout prefilled with customer contact info.
4. **Signature Verification & Capture**:
   Upon successful payment in the modal, the `handler` callback receives `razorpay_payment_id` and `razorpay_signature` and posts them to `PATCH /api/v3/store/carts/:id/payment_sessions/:id/complete`. The backend verifies the HMAC SHA256 signature against your `key_secret` and transitions the payment session to `completed`.
5. **Order Completion**:
   The storefront calls `onPaymentComplete({ type: "session" })`, which finalizes the checkout through `Spree::Carts::Complete`.

