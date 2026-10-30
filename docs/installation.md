# Installing Spree Razorpay

This guide walks you through installing the **Spree Razorpay** payment gateway on a Spree 6.0+ application.

---

## 1. Prerequisites & System Requirements

Before installing, ensure your environment meets the minimum version requirements:

- **Ruby**: `>= 3.2.0` (Tested on Ruby 4.0.9)
- **Rails**: `>= 7.1.0`, `< 9.0.0` (Tested on Rails 8.1.4)
- **Spree Commerce**: `~> 6.0.0` (Tested on Spree 6.0.1)
- **Razorpay Account**: Active account on [Razorpay Dashboard](https://dashboard.razorpay.com/) (Test or Live mode)

> [!NOTE]
> **Zero Database Migrations Required**
> `spree_razorpay` uses Spree 6's native `Spree::Gateway` and `Spree::PaymentSession` tables (`spree_payment_methods`, `spree_payments`, `spree_payment_sessions`). You do **not** need to run `spree migrate` or copy any migrations.

---

## 2. Installation Methods

### Method A: Official Spree CLI (Docker-Managed Projects — Recommended)

If you are running Spree via the official `@spree/cli`:

```bash
# 1. Add the gem to server/Gemfile (defaults to main for Spree 6)
pnpm spree bundle add spree_razorpay --github "umeshravani/spree_razorpay"

# 2. Run the Rails installation generator (seeds the payment gateway)
pnpm spree rails g spree_razorpay:install

# 3. Restart the Spree development stack to load initializers
pnpm spree restart
```

---

### Method B: Conventional Rails Application (Host-Managed)

If you are running a standard Rails project without Docker:

```bash
# 1. Add the gem to your Gemfile
bundle add spree_razorpay --github "umeshravani/spree_razorpay"

# 2. Run the install generator
bin/rails g spree_razorpay:install

# 3. Restart your Rails server
bin/rails restart
```

---

### Method C: Production Docker & Coolify Deployments

In containerized production setups (such as Coolify, Docker Compose, or Kubernetes):

1. **Add Gem to `server/Gemfile`**:
   ```ruby
   # Spree 6 (Recommended):
   gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', branch: 'main'

   # Or pinned to an immutable release SHA:
   # gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', ref: '844be28d4034416420e56388fdfefd1491e17c2e'
   ```
2. **Update Lockfile in Docker Dev**:
   ```bash
   pnpm spree exec bundle lock --conservative
   ```
3. **Configure Environment Variables in Coolify**:
   Add the credentials to your application environment settings:
   ```env
   RAZORPAY_KEY_ID=rzp_live_...
   RAZORPAY_KEY_SECRET=your_live_key_secret
   RAZORPAY_WEBHOOK_SECRET=your_webhook_signing_secret
   RAZORPAY_AUTO_CAPTURE=true
   ```
4. **Trigger Deployment**:
   Coolify builds the Docker image and reboots the container with the newly bundled gem.

---

### Method D: Installing Both Razorpay & Delhivery Together

If your store uses both Razorpay (for online payments) and Delhivery (for shipping & COD):

```ruby
# server/Gemfile
gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', branch: 'main'
gem 'spree_delhivery', github: 'umeshravani/spree_delhivery', branch: 'main'
```

Run installation:
```bash
# Bundle dependencies
pnpm spree bundle install

# Run generators for both extensions
pnpm spree rails g spree_razorpay:install
pnpm spree rails g spree_delhivery:install
```

---

### Legacy Spree 5 Support

For legacy stores running Spree Commerce 5.x, reference the preserved `spree-5` branch:

```ruby
gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', branch: 'spree-5'
```

# Restart services
pnpm spree restart
```

---

## 3. Post-Installation Verification

To verify that the extension loaded and registered with Spree:

```bash
# In Spree CLI
pnpm spree console

# Or in Rails console
bin/rails c
```

Run:
```ruby
# Verify Gateway is registered in Spree allowlist
Rails.application.config.spree.payment_methods.include?(SpreeRazorpay::Gateway)
# => true

# Verify Gateway record exists in database
Spree::PaymentMethod.find_by(type: 'SpreeRazorpay::Gateway')
# => #<SpreeRazorpay::Gateway id: 1, name: "Razorpay", active: true ...>
```

---

## 4. Dashboard Connection and Disconnection

Once the gem is installed, manage the gateway directly through the Spree Admin Dashboard without code modifications:

### Connecting the Gateway
1. Navigate to **Settings $\rightarrow$ Payments $\rightarrow$ Razorpay**.
2. Enter your **Key ID**, encrypted **Key Secret**, and webhook secret.
3. Toggle **Active** and **Storefront Visible** to `Yes`.
4. Click **Save Changes**. The gateway is now connected and available to shoppers.

### Disconnecting the Gateway (Safe Deactivation)
1. Navigate to **Settings $\rightarrow$ Payments $\rightarrow$ Razorpay**.
2. Toggle **Active** and **Storefront Visible** to `No`.
3. Click **Save Changes**.
4. The gateway is instantly disconnected from checkout while preserving 100% of past payment transactions and order histories.

Next, proceed to [Configuration Guide](./configuration.md) to set up your API keys and webhook endpoints.

