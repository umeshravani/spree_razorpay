# Configuring Spree Razorpay

This guide explains how to configure Razorpay API credentials, payment capture rules, webhooks, and test-mode simulation.

---

## 1. Credentials & Configuration Options

| Option / Parameter | Environment Variable | Admin UI Field | Required | Description |
|:---|:---|:---|:---|:---|
| **Key ID** | `RAZORPAY_KEY_ID` | `Key ID` | **Yes** | Your Razorpay API Key ID (`rzp_test_...` or `rzp_live_...`). |
| **Key Secret** | `RAZORPAY_KEY_SECRET` | `Key Secret` | **Yes** | Your Razorpay Secret Key. Stored encrypted at rest via Rails Active Record encryption. |
| **Webhook Secret** | `RAZORPAY_WEBHOOK_SECRET` | `Webhook Secret` | Recommended | Secret token used to verify HMAC-SHA256 signatures on inbound webhook events. |
| **Auto Capture** | `RAZORPAY_AUTO_CAPTURE` | `Auto Capture` | Optional | Set to `true` (default) to capture funds immediately upon authorization. |
| **Display Name** | `RAZORPAY_NAME` | `Name` | Optional | Customer-facing label (e.g. `Razorpay (UPI, Cards, NetBanking)`). |

> [!WARNING]
> **Protect Your Secrets**
> Never pass API keys or secrets directly in shell arguments or commit them to Git. Always configure them via:
> 1. Protected environment variables in your hosting dashboard (Coolify, Render, Heroku).
> 2. The Spree Admin interface (stored encrypted in `secret_preferences`).

---

## 2. Configuration via Spree Admin UI

1. Open your Spree Admin Dashboard (typically at `http://localhost:5173` in development or `/admin` in production).
2. Navigate to **Settings $\rightarrow$ Payments**.
3. Locate **Razorpay** in the list of available payment methods, or click **New Payment Method**.
4. Configure the settings:
   - **Provider**: Select `SpreeRazorpay::Gateway`.
   - **Name**: `Razorpay` (or `Credit/Debit Card, UPI, NetBanking`).
   - **Active**: Check `Yes` to enable for your store.
   - **Storefront Visible**: Check `Yes` to display on the customer checkout page.
5. Under **Gateway Preferences**:
   - **Key ID**: Enter your `rzp_test_...` or `rzp_live_...` key.
   - **Key Secret**: Enter your Razorpay secret.
   - **Auto Capture**: Checked (`true`) is recommended.
   - **Webhook Secret**: Enter your webhook secret token.
6. Click **Save Changes**.

---

## 3. Configuring Inbound Webhooks

Webhooks allow Razorpay to notify your Spree store asynchronously if a payment was authorized off-session, or if a refund succeeded.

### Step 1: Obtain the Webhook URL
In Spree 6 API V3, the standardized payment webhook URL is:

```text
https://your-store.com/api/v3/webhooks/payments/<PAYMENT_METHOD_ID>
```

*(Replace `<PAYMENT_METHOD_ID>` with the integer or prefixed ID of your Razorpay payment method record in Spree Admin, e.g., `3` or `pm_k5nR8xLq`)*

### Step 2: Configure in Razorpay Dashboard
1. Log into your [Razorpay Dashboard](https://dashboard.razorpay.com/).
2. Go to **Settings $\rightarrow$ Webhooks $\rightarrow$ Add New Webhook**.
3. Set **Webhook URL** to your Spree endpoint.
4. Set **Secret** to a secure random string (e.g., generated with `openssl rand -hex 20`).
5. Select the following events:
   - `payment.authorized`
   - `payment.captured`
   - `payment.failed`
   - `refund.processed`
   - `refund.failed`
6. Click **Create Webhook**.
7. Copy the secret and paste it into **Webhook Secret** in your Spree Admin Razorpay settings.

---

## 4. Test Mode vs. Live Production Mode

Razorpay determines whether a transaction is live or simulated based solely on the Key ID prefix:

- **Test Mode**: Keys starting with `rzp_test_...` simulate payments without moving real money.
  - Test Card: `4111 1111 1111 1111` (any future expiry, any CVV).
  - Test UPI: `success@razorpay` (instant success) or `failure@razorpay` (instant failure).
- **Live Mode**: Keys starting with `rzp_live_...` process real financial transactions in INR or configured international currencies.

Switching between test and live modes only requires swapping the `Key ID` and `Key Secret` in Spree Admin and saving. No server reboot or code changes are required.
