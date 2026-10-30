# Upgrading Spree Razorpay

This guide explains how to safely update the `spree_razorpay` extension in your Spree store.

---

## 1. Upgrading the Gem Version

### Step 1: Update Gemfile
If pinning to a specific release tag or commit SHA, update `server/Gemfile`:

```ruby
# Example: updating to a specific verified git ref
gem 'spree_razorpay', github: 'umeshravani/spree_razorpay', ref: '844be28d4034416420e56388fdfefd1491e17c2e'
```

### Step 2: Run Conservative Bundle Update
Always use `--conservative` to prevent Bundler from unexpectedly bumping unrelated gems (such as Rails, Spree core, or Puma):

```bash
# In Spree CLI
pnpm spree exec bundle update spree_razorpay --conservative

# In standard Rails
bundle update spree_razorpay --conservative
```

### Step 3: Run Test Suite
Verify that your existing test suite passes after the dependency update:

```bash
pnpm spree rspec spec/models/spree/razorpay_spec.rb
```

### Step 4: Restart Server
Gem updates modify loaded class definitions and initializers, requiring a restart of all running web and background worker processes:

```bash
pnpm spree restart
```

---

## 2. Upgrading When Spree Core Upgrades (e.g. 6.0.1 $\rightarrow$ 6.0.2)

Because `spree_razorpay` relies on standard Spree provider contracts without monkey patches:

1. **Review CHANGELOG.md**: Check for any newly introduced preferences or configuration changes.
2. **Check Gem Compatibility**: Ensure `spree_core` constraint in `spree_razorpay.gemspec` matches your new Spree version (`~> 6.0.0` automatically accommodates point releases).
3. **No Migrations Needed**: Spree core upgrades may run `spree migrate`, but `spree_razorpay` itself requires zero migrations.

