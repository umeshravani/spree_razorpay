# Disabling and Uninstalling Spree Razorpay

This document details the lifecycle management of `spree_razorpay`, contrasting safe operational deactivation in the dashboard with experimental gem removal and historical data integrity.

---

## 1. Disabling vs. Uninstalling: At a Glance

| Operation | Action Required | Historical Orders & Invoices | Storefront Checkout | Risk Level | Support Status |
|:---|:---|:---|:---|:---|:---|
| **Disabling (Normal)** | Uncheck `Active` in Spree Admin | **100% Preserved & Auditable** | Instantly Hidden | **Zero Risk** | **Fully Supported & Recommended** |
| **Code Removal (Gem)** | Remove gem from `Gemfile` with shim | **Viewable, but runtime methods missing** | Hidden | **High Risk** | **Advanced & Experimental** |

---

## 2. Recommended Safe Procedure: Disabling in Spree Admin

To stop offering Razorpay to customers without endangering your financial history:

1. Log into **Spree Admin**.
2. Navigate to **Settings $\rightarrow$ Payments**.
3. Click on the **Razorpay** payment method.
4. Set **Active** to `No` (uncheck the box).
5. Set **Storefront Visible** to `No` (uncheck the box).
6. Click **Save**.

### What Happens When Disabled:
- Razorpay immediately disappears from the customer checkout payment options.
- Existing placed orders, customer order summaries, receipts, and invoices remain fully functional.
- Staff can continue inspecting historical transaction IDs (`pay_...`), authorizations, and captured amounts in the Admin order view.
- Issuing refunds on previously captured Razorpay orders continues to work as long as the gem remains installed.

---

## 3. The Rails Single Table Inheritance (STI) Hazard

> [!CAUTION]
> **ActiveRecord::SubclassNotFound Warning**
> Spree stores the Ruby class name `SpreeRazorpay::Gateway` directly in the `type` column of `spree_payment_methods`. It also stores `Spree::PaymentSessions::Razorpay` in `spree_payment_sessions.type`.
>
> If you delete `gem 'spree_razorpay'` from your `Gemfile` without defining these classes, Rails will fail whenever orders or payment methods are loaded:
> ```text
> ActiveRecord::SubclassNotFound: The single-table inheritance mechanism failed to locate the subclass: 'SpreeRazorpay::Gateway'
> ```

### Never Delete or Retype Historical Financial Records
Never execute SQL queries deleting payment records or reassigning `spree_payment_methods.type` or `spree_payments.payment_method_id` to `Spree::PaymentMethod::Bogus` or `Spree::PaymentMethod::Check`.
- It violates accounting and tax compliance by falsifying payment processor records.
- It destroys the ability to audit gateway transaction IDs (`pay_...`), dispute records, and authorizations.
- It breaks automated refund tracking.

---

## 4. Advanced & Experimental: Code Removal Compatibility Shim

> [!WARNING]
> **Unsupported for Production Stores with Historical Transactions**
> Complete gem uninstallation is NOT recommended if your store has processed real transactions. While a minimal Ruby class shim prevents immediate `ActiveRecord::SubclassNotFound` errors when loading basic records, historical refund processing, webhook verification, and background jobs will fail if they invoke methods on the missing gem classes.
>
> Disabling in the Spree Admin Dashboard (Section 2) is the only fully tested, supported, and zero-risk procedure.

If you are running an experimental or non-production environment where the gem must be pruned from `Gemfile`, you must define empty class shims in your host application:

```ruby
# server/app/models/spree_razorpay/gateway.rb
module SpreeRazorpay
  class Gateway < Spree::PaymentMethod
    def self.model_name
      Spree::PaymentMethod.model_name
    end
  end
end

# server/app/models/spree/payment_sessions/razorpay.rb
module Spree
  module PaymentSessions
    class Razorpay < Spree::PaymentSession
    end
  end
end
```

### Limitations of the Compatibility Shim:
1. **No Refund Processing**: Calling `.refund` or issuing a refund from the Admin order view will raise `NoMethodError`.
2. **No Webhook Handlers**: Incoming Razorpay webhooks for historical events will raise exceptions.
3. **No Payment Re-capture**: Authorizations cannot be captured or settled.
4. **Read-Only Inspection Only**: The shim is strictly suitable for basic read-only display of past orders.
