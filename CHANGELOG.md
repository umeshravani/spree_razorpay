# Changelog

All notable changes to the `spree_razorpay` gem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

Changes verified against Spree 6.0.1 on the `spree-6` branch (pending release tagging):

### Added
- Standardized documentation suite in `docs/`:
  - `installation.md`: Detailed Spree CLI, standard Rails, and Coolify guides.
  - `configuration.md`: Admin dashboard configuration, exact environment variables, and webhook routing.
  - `disabling-and-uninstalling.md`: Safe dashboard deactivation vs experimental STI shims.
  - `compatibility.md`: Tested runtime matrix and Spree 5 vs 6 architecture guide.
  - `upgrading.md`: Maintenance and safe upgrade procedures.
  - `storefront.md`: Optional Next.js App Router reference guide and modal integration.
  - `screenshots.md`: Visual inventory with capture standards and privacy masking rules.
- Thread-isolated custom headers via `Thread.current[:razorpay_custom_headers]` for concurrent Puma/Solid Queue execution.
- Deterministic refund receipt derivation (`ref_#{originator.id}`) and strict matching for full and partial refunds.
- Safe balance validation using `payment.with_lock` before issuing refunds.
- Multi-threading concurrency regression specs in `spec/models/spree_razorpay/gateway_spec.rb`.
- Rails install generator `rails g spree_razorpay:install`.
- Interactive setup task `rake spree_razorpay:setup`.

### Changed
- Verified full compatibility with Spree 6.0.1 and Rails 8.1.4 on Ruby 4.0.9.
- Updated documentation links and verified Spree CLI commands.

---

## [Historical Spree 6 Work]

### Added
- Native Spree 6 API V3 Payment Sessions architecture (`/payment_sessions`).
- Modal checkout integration using Razorpay `checkout.js` in Next.js Storefront.
- Cryptographic HMAC-SHA256 signature verification on payment completion.
- Rails Active Record encryption at rest for `key_secret` and `webhook_secret`.
