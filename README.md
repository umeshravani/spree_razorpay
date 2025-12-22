<img 
  src="https://github.com/user-attachments/assets/3bcca1bd-5d70-4f0e-9c6d-4f99104d0e93" 
  alt="razorpay" 
  style="height: 100px; border-radius: 12em;"
/>

This Razorpay Checkout Reprository is mentioned in official [Spree Commerce Docs](https://spreecommerce.org/docs/integrations/payments/razorpay).

## Razorpay Extension for Spree Commerce v5.2
RazorPay is the only payments solution in India that allows businesses to accept, process and disburse payments with its product suite.

## Installation

1. Add Gem:

    ```ruby
    bundle add spree_razorpay_checkout
    ```

2. Install the Gem:

    ```ruby
    bundle exec rails g spree_razorpay_checkout:install
    ```

3. Compile Assets (Optional):
    ```ruby
    bin/rails assets:precompile
    ```
    
4. Start Server:
   ```ruby
    foreman start -f Procfile.dev
    ```
## Render Widget in Product Details:

1. Find your Partial file Example: 
    ```
    'app/views/themes/default/spree/page_sections/_product_details.html.erb'
    ```
    Note: If you dont find this file inside your spree's directory, You can [Download](https://github.com/spree/spree/blob/df400d3557c244ec3829f175a27f3990cdeb2452/storefront/app/views/themes/default/spree/page_sections/_product_details.html.erb#L4) this directly from Spree's Github and place it exactly inside your Spree's directory

2. Place this Rendering Code:
   ```
    <% when 'Spree::PageBlocks::Products::RazorpayAffordability' %>
    <%# We call your custom render method defined in the model %>
    <%= block.render(self, product: product) %>
   ```
   Exactly below this part:
   ```
   <% when 'Spree::PageBlocks::Products::Description' %>
   ```

## Installation (For Docker)

1. Add Gem using docker compose:

    ```ruby
    docker compose run web bundle add spree_razorpay_checkout
    ```

2. Install the Gem using Docker's Bundle Install:

    ```ruby
    docker compose run web bundle exec rails g spree_razorpay_checkout:install
    ```

3. Compile Assests for Razorpay logo & assets (Recommended):
   
    ```ruby
    docker compose run web bundle exec rails assets:precompile
    ```
    
4. Re-Start Server (Recommended):

    ```ruby
    docker compose down
    docker compose up -d
    ```
## Upgrade to Latest Version:

1. Change version in Spree's GemFile:

    ```ruby
    gem "spree_razorpay_checkout", "~> 0.1.1"
    ```

2. Run Bundle Updator to Patch updated files:

    ```ruby
    bundle update
    ```

3. Migrate Database Tables (Recommended):
   
    ```ruby
    rails db:migrate
    ```
    
4. Re-Start Server (Recommended):

    ```ruby
    bin/rails restart
    ```

## Plugin Configuration
1. Get keys from Razorpay Dashboard [here](https://dashboard.razorpay.com/app/website-app-settings/api-keys).

   <img width="1186" height="735" alt="razorpay dashboard" src="https://github.com/user-attachments/assets/f390685d-550b-4814-8785-4fcc32746f15" />

2. Make Sure to include both Razorpay Live & Test Keys from Razorpay Dashboard:

<img width="1121" height="736" alt="Admin Dashboard - Razorpay Plugin" src="https://github.com/user-attachments/assets/f45efc43-b1db-4c79-9ad3-e3d672014676" />


3. Drag Razorpay to Top in Payment Methods to make it Default:

<img width="1121" height="726" alt="Payment Methods - Razorpay Plugin" src="https://github.com/user-attachments/assets/8e39086d-85a6-42a2-b9fb-75299044e6d6" />

## Checkout View

4. Checkout Page:
   
<img width="507" height="639" alt="Razorpay Checkout Page" src="https://github.com/user-attachments/assets/ddca8536-fa94-4502-96fa-4cd2219f3c17" />

5. Razorpay Modal to Capture Payments:

<img width="767" height="728" alt="Razorpay Modal" src="https://github.com/user-attachments/assets/da83105f-8510-44ae-ac7c-28960cf3a0b3" />

6. Order Page (Customer View):

<img width="940" height="648" alt="Customers Orders Page Razorpay Spree" src="https://github.com/user-attachments/assets/3361da09-9f01-4101-8c3e-de5ae94394de" />

7. Order Page (Admin View):

<img width="800" height="562" alt="Admin Orders Page Razorpay Spree" src="https://github.com/user-attachments/assets/895b1081-e20a-47b8-845f-ce2eb621acd7" />

Thankyou for supporting this plugin. if you find any issues related to plugin you are open to contribute and support which can help more Spree users in India.

## Gem Info

- [RubyGems Page](https://rubygems.org/gems/spree_razorpay_checkout)
- [Source Code](https://github.com/umeshravani/spree_razorpay)
- [Bug Reports](https://github.com/umeshravani/spree_razorpay/issues)

---

## Uninstallation

1. Uninstall Gem:

    ```ruby
    gem uninstall spree_razorpay_checkout
    gem uninstall razorpay
    ```

2. Update Gemfile:

    ```ruby
    bundle install
    ```
    
3. Remove Migrations:

    ```ruby
    rm db/migrate/*_create_spree_razorpay_checkouts.spree_razorpay_checkout.rb
    ```
    
4. Open Rails Console:
   
   ```ruby
    rails c 

5. Drop Razorpay Database:
   
   ```ruby
    ActiveRecord::Base.connection.drop_table(:spree_razorpay_checkouts)
    ``````
6. Check Razorpay (You should see "nill"):
   
   ```ruby
    defined?(Razorpay) # => nil  
    ```
 Note: If you see "nill" then Razorpay is completely uninstalled from Spree commerce, either if you see "constant" try "gem uninstall razorpay" & "bundle update".


### Roadmap

| **Features**                                              | **Progress** | **Status** |
|-----------------------------------------------------------|--------------|------------|
| Auto-Capture Order in Razorpay                            | Working      | ✅         |
| Test Button for Testmode                                  | Working      | ✅         |
| Razorpay order creation using [OrdersAPI](https://razorpay.com/docs/payments/orders/apis/) | Working    | ✅        |
| Fetching Exact Total Amount in Modal                      | Working      | ✅         |
| Order Creation after Successful Payment                   | Working      | ✅         |
| Razorpay Logo in Admin/Order's Page                       | Working      | ✅         |
| Admin side "Capture" order button                         | Working      | ✅         |
| Admin side "Cancel" order button                          | Working      | ✅         |
| Admin side "Refund" order button                          | Pending      | ❌         |
| E-Mail after successful order                             | Working      | ✅         |
| Disable Pay Button for Accidental Order                   | Working      | ✅         |
| Razorpay Affordability Widget in Product Details Page     | Upcoming     | ⏳         |

### Contributing

Contributions are welcome! Please open issues or submit pull requests to help improve this plugin for the Spree + Razorpay community in India.
