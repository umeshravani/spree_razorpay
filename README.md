# Spree Razorpay (Spree 6 Commerce)

[![Spree Commerce](https://img.shields.io/badge/Spree-6.0.1%20Tested-red.svg)](https://spreecommerce.org)
[![Rails Version](https://img.shields.io/badge/Rails-8.1.4-blue.svg)](https://rubyonrails.org)
[![Ruby Version](https://img.shields.io/badge/Ruby-4.0.9-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A third-party community extension connecting **[Razorpay](https://razorpay.com)** to **Spree Commerce 6**.

Provides backend Rails API V3 payment sessions for UPI, Credit/Debit Cards, NetBanking, and Wallets, with an optional reference integration for the Spree Next.js Storefront.

---

## Features

- **Spree 6 Native Payment Sessions**: Seamlessly integrated into API V3 payment sessions (`/payment_sessions`).
- **Encrypted at Rest**: API secrets are encrypted using Rails Active Record encryption (`V-3730`).
- **Exact Decimals & Money Correctness**: Standardized on Spree 6 money architecture with `BigDecimal` amounts.
- **Cryptographic Signature Verification**: Validates `razorpay_payment_id`, `razorpay_order_id`, and `razorpay_signature` via HMAC-SHA256 upon completion before order finalization.
- **Thread-Safe & Concurrent**: Isolated request headers and database row-locking for idempotent payments and refunds.
- **Zero Database Migrations**: Uses native Spree core tables (`spree_payment_methods`, `spree_payments`, `spree_payment_sessions`).
- **Optional Next.js Storefront Modal**: Step-by-step reference guide and components for embedding Razorpay Standard Checkout (`checkout.js`) with customer contact prefill.

---

## Compatibility

| Component | Verified Tested Version | Intended Compatibility Range |
|:---|:---|:---|
| **Spree Commerce** | `6.0.1` | `~> 6.0.0` |
| **Ruby on Rails** | `8.1.4` | `>= 7.1.0, < 9.0.0` |
| **Ruby** | `4.0.9` | `>= 3.2.0` |
| **Storefront** | Next.js `16.0.x` | Spree 6 Next.js Storefront (API V3) |

*For complete details, see [docs/compatibility.md](./docs/compatibility.md).*

---

## Installation & Deployment

### Method 1: Spree CLI (Docker Starter Projects — Recommended)

```bash
# 1. Add to server/Gemfile
pnpm spree bundle add spree_razorpay --github "umeshravani/spree_razorpay" --branch "spree-6"

# 2. Run the installation generator
pnpm spree rails g spree_razorpay:install

# 3. Restart the Spree development stack
pnpm spree restart
```

### Method 2: Standard Rails (Non-Docker)

```bash
# 1. Add to Gemfile
bundle add spree_razorpay --github "umeshravani/spree_razorpay" --branch "spree-6"

# 2. Run the installation generator
bin/rails g spree_razorpay:install

# 3. Restart Rails server
bin/rails restart
```

### Method 3: Production Docker / Coolify Deployment

In containerized deployments:
1. Add the pinned gem to `server/Gemfile`:
   ```ruby
   gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', branch: 'spree-6'
   ```
2. Lock dependencies: `pnpm spree bundle lock`
3. Set environment variables in Coolify / Docker Compose (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `RAZORPAY_AUTO_CAPTURE`).
4. Run seeds during post-deployment release phase: `pnpm spree rails spree_razorpay:seeds`.

*For combined installation with Delhivery, see [docs/installation.md](./docs/installation.md).*

---

## Dashboard Connection & Disconnection

### Connecting the Gateway
1. Open your Spree Admin Dashboard (`/admin` or `http://localhost:5173`).
2. Navigate to **Settings $\rightarrow$ Payments**.
3. Select **Razorpay** and enter:
   - **Key ID**: Your Razorpay Key ID (`rzp_test_...` or `rzp_live_...`)
   - **Key Secret**: Your Razorpay Secret Key (stored encrypted at rest)
   - **Auto Capture**: Checked (`true`)
   - **Webhook Secret**: Your webhook signing secret
4. Set **Active** and **Storefront Visible** to `Yes` and click **Save**.

### Disconnecting the Gateway (Safe Deactivation)
To immediately stop offering Razorpay to shoppers:
1. Navigate to **Settings $\rightarrow$ Payments $\rightarrow$ Razorpay**.
2. Set **Active** and **Storefront Visible** to `No` and click **Save**.
- Razorpay disappears from checkout immediately.
- Historical orders, invoices, transaction references, and refunds remain fully functional.
- No code or database changes are required.

> [!WARNING]
> Never delete or retype historical payment records in the database. Disabling via the Admin Dashboard is the only supported, zero-risk method. Gem removal with compatibility shims is advanced and experimental (see [docs/disabling-and-uninstalling.md](./docs/disabling-and-uninstalling.md)).

---

## Optional Next.js Storefront Integration

The `spree_razorpay` gem handles all backend Rails API V3 payment sessions. Integrating the checkout popup into your Next.js storefront involves 4 frontend steps:
1. Adding the SVG payment badge.
2. Registering the `"razorpay"` gateway type.
3. Adding the `RazorpayPaymentForm.tsx` modal launcher.
4. Mounting inside `PaymentSection.tsx`.

👉 **[Complete Step-by-Step Storefront Guide](./docs/storefront.md)**

---

## Screenshots

| Admin Integrations Gallery | Storefront Checkout (Optional) |
|:---:|:---:|
| ![Admin Integrations](./docs/assets/screenshots/01-admin-integrations-gallery.png) | ![Storefront Checkout](./docs/assets/screenshots/04-storefront-checkout-payment-option.png) |

*For the complete screenshot inventory and masking checklist, see [docs/screenshots.md](./docs/screenshots.md).*

---

## Documentation Index

- [Installation Guide](./docs/installation.md)
- [Configuration & Webhooks](./docs/configuration.md)
- [Next.js Storefront Setup (Optional)](./docs/storefront.md)
- [Disabling & Safe Removal](./docs/disabling-and-uninstalling.md)
- [Compatibility Matrix](./docs/compatibility.md)
- [Upgrading Guide](./docs/upgrading.md)
- [Screenshots Checklist & Privacy](./docs/screenshots.md)
- [Changelog](./CHANGELOG.md)

---

## License

Spree Razorpay is released under the [MIT License](LICENSE).
