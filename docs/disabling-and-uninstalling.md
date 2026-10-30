# Disabling and Uninstalling Spree Razorpay

This document details the lifecycle management of `spree_razorpay`, contrasting safe operational deactivation with complete gem uninstallation and historical data integrity.

---

## 1. Disabling vs. Uninstalling: At a Glance

| Operation | Action Required | Historical Orders & Invoices | Storefront Checkout | Risk Level |
|:---|:---|:---|:---|:---|
| **Disabling (Normal)** | Uncheck `Active` in Spree Admin | **100% Preserved & Auditable** | Instantly Hidden | **Zero Risk** (Recommended) |
| **Code Removal (Gem)** | Remove `spree_razorpay` from `Gemfile` | **Corrupted unless pre-cleaned** | Hidden | **High Risk** (STI Crash) |

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
- Issuing refunds on previously captured Razorpay orders continues to work as long as the gem is loaded.

---

## 3. The Rails Single Table Inheritance (STI) Removal Pitfall

> [!CAUTION]
> **ActiveRecord::SubclassNotFound Warning**
> Spree stores the Ruby class name `SpreeRazorpay::Gateway` directly in the `type` column of `spree_payment_methods`. It also stores `Spree::PaymentSessions::Razorpay` in `spree_payment_sessions.type`.
>
> If you delete `gem 'spree_razorpay'` from your `Gemfile` without archiving or cleaning the database, Rails will fail with the following error whenever orders or payment methods are loaded:
> ```text
> ActiveRecord::SubclassNotFound: The single-table inheritance mechanism failed to locate the subclass: 'SpreeRazorpay::Gateway'
> ```

### Why You Should NOT Reassign Historical Records to Bogus
Do not execute SQL queries reassigning `spree_payment_methods.type` or `spree_payments.payment_method_id` to `Spree::PaymentMethod::Bogus` or `Spree::PaymentMethod::Check`. Doing so violates financial auditing integrity:
- It falsifies the merchant processing record of which gateway collected the funds.
- It destroys the ability to trace gateway transaction IDs (`pay_...`) and dispute records.
- It breaks automated refund tracking.

---

## 4. Complete Code Removal Procedure (If Gem Must Be Removed)

If your organization permanently replaces Razorpay and policy requires removing the Ruby gem from the repository bundle, follow this procedure:

### Step 1: Verify No Active Carts or Pending Sessions
Ensure no open customer carts or in-flight checkouts are currently holding pending Razorpay payment sessions:

```ruby
# In Rails console
Spree::PaymentSession.where(type: 'Spree::PaymentSessions::Razorpay', status: %w[pending processing]).count
```

### Step 2: Archive or De-link Payment Methods
If you have completed historical orders with Razorpay, the database needs a class definition so Active Record can instantiate the records.

Instead of hacking database tables, keep a lightweight, no-dependency compatibility shim in your host application:

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

This 15-line stub in your application allows:
1. `gem 'spree_razorpay'` to be safely removed from `Gemfile`.
2. All historical admin order pages to open without `ActiveRecord::SubclassNotFound`.
3. Historical financial audits to remain truthful and intact.
