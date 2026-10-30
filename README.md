# Spree Razorpay (Spree 6 Commerce)

[![Spree Commerce](https://img.shields.io/badge/Spree-6.0.1-red.svg)](https://spreecommerce.org)
[![Rails Version](https://img.shields.io/badge/Rails-8.1.4-blue.svg)](https://rubyonrails.org)
[![Ruby Version](https://img.shields.io/badge/Ruby-4.0.9-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An official-grade, beginner-friendly payment gateway integration connecting **[Razorpay](https://razorpay.com)** to **Spree Commerce 6**.

Supports UPI, Credit/Debit Cards, NetBanking, and Wallets using Razorpay Standard Checkout in the official Spree 6 Next.js Storefront.

---

## Features

- **Spree 6 Native Payment Sessions**: Seamlessly integrated into API V3 payment sessions (`/payment_sessions`).
- **Encrypted at Rest**: API secrets are encrypted using Rails Active Record encryption (`V-3730`).
- **Exact Decimals & Money Correctness**: Standardized on Spree 6 money architecture with `BigDecimal` amounts.
- **Cryptographic Signature Verification**: Validates `razorpay_payment_id`, `razorpay_order_id`, and `razorpay_signature` via HMAC-SHA256 upon completion before order finalization.
- **Thread-Safe & Concurrent**: Isolated request headers and database row-locking for idempotent payments and refunds.
- **Zero Database Migrations**: Uses native Spree core tables (`spree_payment_methods`, `spree_payments`, `spree_payment_sessions`).
- **Next.js Storefront Modal**: Interactive popup checkout using Razorpay's `checkout.js` with customer contact prefill.

---

## Compatibility

| Component | Verified Tested Version | Intended Compatibility Range |
|:---|:---|:---|
| **Spree Commerce** | `6.0.1` | `~> 6.0.0` |
| **Ruby on Rails** | `8.1.4` | `>= 7.1.0, < 9.0.0` |
| **Ruby** | `4.0.9` | `>= 3.2.0` |
| **Storefront** | Next.js `16.0.x` | Spree 6 Next.js Storefront |

*For complete details, see [docs/compatibility.md](./docs/compatibility.md).*

---

## Quickstart Installation

### With Spree CLI (Docker Starter Projects)

```bash
# 1. Add to server/Gemfile
pnpm spree bundle add spree_razorpay --github "umeshravani/spree_razorpay" --branch "spree-6"

# 2. Run the installation generator
pnpm spree rails g spree_razorpay:install

# 3. Restart the Spree development stack
pnpm spree restart
```

### With Standard Rails (Non-Docker)

```bash
# 1. Add to Gemfile
bundle add spree_razorpay --github "umeshravani/spree_razorpay" --branch "spree-6"

# 2. Run the installation generator
bin/rails g spree_razorpay:install

# 3. Restart Rails server
bin/rails restart
```

*For production deployment (Coolify/Docker) and combined installation with Delhivery, see [docs/installation.md](./docs/installation.md).*

---

## Configuration

### 1. Spree Admin Dashboard (Recommended)

1. Open your Spree Admin Dashboard (`/admin` or `http://localhost:5173`).
2. Navigate to **Settings $\rightarrow$ Payments**.
3. Select **Razorpay** and enter:
   - **Key ID**: Your Razorpay Key ID (`rzp_test_...` or `rzp_live_...`)
   - **Key Secret**: Your Razorpay Secret Key (stored encrypted)
   - **Auto Capture**: Checked (`true`)
   - **Webhook Secret**: Your webhook signing secret
4. Set **Active** and **Storefront Visible** to `Yes` and click **Save**.

### 2. Environment Variables

Alternatively, configure via protected environment variables in your deployment:

```env
RAZORPAY_KEY_ID=rzp_live_...
RAZORPAY_KEY_SECRET=your_secret_key
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
RAZORPAY_AUTO_CAPTURE=true
```

> [!WARNING]
> Never commit live credentials to Git or pass secrets in command-line arguments.

*For inbound webhook routing and test cards, see [docs/configuration.md](./docs/configuration.md).*

---

## Next.js Storefront Integration

Integrating Razorpay into your Next.js storefront involves 4 clean steps:
1. Adding the official SVG security badge.
2. Registering the `"razorpay"` gateway type.
3. Adding the `RazorpayPaymentForm.tsx` modal launcher.
4. Mounting inside `PaymentSection.tsx`.

👉 **[Complete Step-by-Step Storefront Guide](./docs/storefront.md)**

---

## Screenshots

| Admin Integrations Gallery | Storefront Checkout |
|:---:|:---:|
| ![Admin Integrations](./docs/assets/screenshots/01-admin-integrations-gallery.png) | ![Storefront Checkout](./docs/assets/screenshots/04-storefront-checkout-payment-option.png) |

*For the complete screenshot inventory and masking checklist, see [docs/screenshots.md](./docs/screenshots.md).*

---

## Disabling and Safe Uninstallation

- **To Temporarily or Permanently Stop Offering Razorpay**:
  Simply set **Active** to `No` in Spree Admin (**Settings $\rightarrow$ Payments**). Razorpay disappears from checkout immediately. All historical orders, payment transactions, and invoices remain 100% intact.
- **Do NOT delete the gem from `Gemfile` without reviewing [docs/disabling-and-uninstalling.md](./docs/disabling-and-uninstalling.md)**:
  Removing the Ruby gem while historical database records reference `type: 'SpreeRazorpay::Gateway'` causes Rails to raise `ActiveRecord::SubclassNotFound`.

---

## Documentation Index

- [Installation Guide](./docs/installation.md)
- [Configuration & Webhooks](./docs/configuration.md)
- [Next.js Storefront Setup](./docs/storefront.md)
- [Disabling & Safe Removal](./docs/disabling-and-uninstalling.md)
- [Compatibility Matrix](./docs/compatibility.md)
- [Upgrading Guide](./docs/upgrading.md)
- [Screenshots Checklist & Privacy](./docs/screenshots.md)
- [Changelog](./CHANGELOG.md)

---

## License

Spree Razorpay is released under the [MIT License](LICENSE).
