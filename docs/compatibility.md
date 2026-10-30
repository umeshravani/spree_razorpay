# Compatibility Matrix: Spree Razorpay

This matrix outlines the formally tested and verified environments for `spree_razorpay`, distinguishing proven test targets from theoretical compatibility ranges.

---

## 1. Verified & Tested Environments

The following combinations have passed full automated test suites (RSpec, Factory Bot, end-to-end checkout, and concurrency tests) in live production and Docker containerized development:

| Component | Tested Version | Test Result | Environment / Notes |
|:---|:---|:---|:---|
| **Spree Commerce** | `6.0.1` | **PASS** (100% specs) | Spree API V3, native payment sessions |
| **Ruby** | `4.0.9` | **PASS** | Default Spree 6 Docker runtime |
| **Ruby on Rails** | `8.1.4` | **PASS** | Active Record encryption (`V-3730`), Solid Queue |
| **Razorpay SDK** | `3.2.0` | **PASS** | Official `razorpay` gem |
| **Storefront** | Next.js `16.0.x` | **PASS** | Modal checkout with `@spree/sdk` |
| **Database** | PostgreSQL `18-alpine` | **PASS** | JSON preferences & Active Record encryption |

---

## 2. Intended Compatibility Range

The gem specification declares the following version constraints:

```ruby
# spree_razorpay.gemspec
s.required_ruby_version = '>= 3.2'
s.add_dependency 'spree_core', '>= 6.0.0'
s.add_dependency 'razorpay', '~> 3.0'
```

- **Ruby**: `>= 3.2.0` (compatible with Ruby 3.2, 3.3, and 4.0)
- **Rails**: `>= 7.1.0`, `< 9.0.0`
- **Spree Commerce**: `~> 6.0.0` (all 6.0.x point releases)

> [!NOTE]
> Versions outside the "Verified & Tested" table (such as Rails 7.2 or Ruby 3.2) are expected to work based on semantic versioning, but have not been tested in the primary test harness.

---

## 3. Spree 5 vs. Spree 6 Breaking Changes

`spree_razorpay` for Spree 6 is **not backward-compatible with Spree 4 or Spree 5**:
1. **Payment Sessions Architecture**: Spree 6 replaced the legacy credit-card form state machine with API V3 payment sessions (`Spree::PaymentSession`).
2. **Exact Decimals**: Spree 6 requires `accepts_money_amounts = true` with `BigDecimal` amounts instead of integer cents in ActiveMerchant.
3. **Admin UI**: Spree 6 deprecated ERB-based `spree_admin` in favor of the React-based `@spree/dashboard` and the Admin API.

