# Razorpay Screenshot Documentation & Asset Checklist

This document defines the screenshot inventory, asset specifications, and privacy masking guidelines for the `spree_razorpay` extension.

All official screenshots must be stored in [`docs/assets/screenshots/`](./assets/screenshots/) using web-optimized PNG or WebP formats.

---

## 1. Privacy & Redaction Guidelines

> [!CAUTION]
> **Zero Exposure of Production Credentials or PII**
> Before uploading any screenshot, verify that all sensitive data is masked, blurred, or replaced with dummy sandbox values.
>
> **Mandatory Redaction Checklist:**
> - **API Keys**: Redact live Key IDs and Key Secrets (e.g., `rzp_live_...`). Test keys (`rzp_test_...`) may be shown only if they are public dummy values.
> - **Webhook Secrets**: Always completely mask webhook signing secrets.
> - **Customer PII**: Redact customer email addresses, real phone numbers, and physical billing/shipping addresses.
> - **Payment Information**: Mask any real credit card numbers, bank account numbers, or UPI IDs. Use official Razorpay test cards (e.g., `4111 1111 1111 1111`).
> - **Internal Infrastructure**: Hide private server hostnames, internal IPs, and internal Coolify resource tokens.

---

## 2. Screenshot Checklist & Inventory

| # | Target Filename | Admin / Storefront Screen | Purpose / Description | Recommended Dimensions | Sensitive Items to Redact |
|:---|:---|:---|:---|:---|:---|
| 1 | `01-admin-integrations-gallery.png` | Spree Admin $\rightarrow$ Settings $\rightarrow$ Payments | Shows Razorpay badge listed under available payment gateways. | 1440 $\times$ 900 px | Host URL, staff email |
| 2 | `02-razorpay-connection-settings.png` | Spree Admin $\rightarrow$ Settings $\rightarrow$ Payments $\rightarrow$ Razorpay | Demonstrates Key ID, Key Secret (masked password field), Auto-Capture, and Webhook Secret configuration. | 1440 $\times$ 960 px | Real Key Secret, live Webhook Secret |
| 3 | `03-payment-method-active-toggle.png` | Spree Admin $\rightarrow$ Payment Methods $\rightarrow$ Edit | Highlights the `Active` and `Storefront Visible` toggles for safe gateway management. | 1200 $\times$ 720 px | None |
| 4 | `04-storefront-checkout-payment-option.png` | Next.js Storefront $\rightarrow$ Checkout $\rightarrow$ Payment Step | Displays "Razorpay Secure Checkout" option with official SVG trust badge. | 1200 $\times$ 800 px | Customer address, cart ID |
| 5 | `05-razorpay-modal-checkout.png` | Next.js Storefront $\rightarrow$ Razorpay `checkout.js` Modal | Shows the standard Razorpay popup with UPI, Card, NetBanking, and Wallet options. | 1000 $\times$ 800 px | Customer phone number, test OTP |
| 6 | `06-order-confirmation-success.png` | Next.js Storefront $\rightarrow$ `/order/[number]` | Displays successful order completion with payment status `Paid`. | 1200 $\times$ 800 px | Customer email, shipping address |
| 7 | `07-admin-order-payment-status.png` | Spree Admin $\rightarrow$ Orders $\rightarrow$ Payments Tab | Shows captured payment transaction, transaction ID (`pay_...`), and gateway response details. | 1440 $\times$ 900 px | Customer PII |
| 8 | `08-admin-refund-interface.png` | Spree Admin $\rightarrow$ Orders $\rightarrow$ Payments $\rightarrow$ Refund | Demonstrates issuing full and partial refunds with cryptographic receipt matching. | 1200 $\times$ 750 px | Internal reference notes |

---

## 3. Placement Convention in Documentation

- In [`README.md`](../README.md): Highlights `01-admin-integrations-gallery.png`, `04-storefront-checkout-payment-option.png`, and `05-razorpay-modal-checkout.png`.
- In [`docs/configuration.md`](./configuration.md): References `02-razorpay-connection-settings.png` and `03-payment-method-active-toggle.png`.
- In [`docs/storefront.md`](./storefront.md): References `04-storefront-checkout-payment-option.png` and `05-razorpay-modal-checkout.png`.
- In [`docs/disabling-and-uninstalling.md`](./disabling-and-uninstalling.md): References `03-payment-method-active-toggle.png` to illustrate safe disabling without gem removal.
