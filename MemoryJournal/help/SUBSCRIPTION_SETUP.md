# In-App Purchase Setup Guide

## Overview
Your Memory Journal app now has a complete subscription system with the following features gated:
- **Videos**: Premium only
- **Photos**: Limited to 5 per entry for free users, unlimited for premium
- **Month Reviews**: Premium only
- **Year Highlights**: Premium only

## Features Implemented

### 1. SubscriptionManager.swift
- Handles all StoreKit 2 subscription logic
- Verifies transactions locally (no backend needed)
- Automatically syncs across devices via Apple ID
- Provides feature access methods

### 2. PaywallView.swift
- Beautiful subscription offer screen
- Shows monthly and yearly options
- Displays premium features
- 7-day free trial included

### 3. Configuration.storekit
- Testing configuration file
- Includes monthly ($4.99/month) and yearly ($39.99/year) subscriptions
- Both include 1-week free trial for testing

### 4. Feature Gating
- **EntryEditor**: Limits photos to 5 and blocks videos for free users
- **ReviewView**: Locks month and year reviews behind premium
- Shows upgrade prompts when users try to access premium features

### 5. SettingsView
- Displays subscription status
- Manage/upgrade subscription
- Restore purchases
- Shows premium features list

## Setup Instructions

### Step 1: Configure StoreKit Testing
1. Open Xcode
2. Go to **Product > Scheme > Edit Scheme**
3. Select **Run** in the left sidebar
4. Go to **Options** tab
5. Under **StoreKit Configuration**, select `Configuration.storekit`

### Step 2: Test the App
You can now run the app and test subscriptions:
- Tap on locked features to see the paywall
- Purchase subscriptions (fake transactions, no real charges)
- Test restore purchases
- Test feature unlocking

### Step 3: Create Products in App Store Connect
When ready for production:

1. **Go to App Store Connect** (https://appstoreconnect.apple.com)
2. Select your app (or create it)
3. Go to **Features > In-App Purchases**
4. Click **+** to create a new subscription
5. Create a **Subscription Group** called "Premium"

6. **Create Monthly Subscription**:
   - Product ID: `com.memoryjournal.premium.monthly`
   - Reference Name: Monthly Premium
   - Price: $4.99/month
   - Add 1-week free trial

7. **Create Yearly Subscription**:
   - Product ID: `com.memoryjournal.premium.yearly`
   - Reference Name: Yearly Premium
   - Price: $39.99/year
   - Add 1-week free trial

### Step 4: Update Product IDs (if needed)
If you want to use different product IDs, update them in:
- `SubscriptionManager.swift` (lines 11-12)
- `Configuration.storekit` (productID fields)

### Step 5: Add Required Capabilities
1. In Xcode, select your project
2. Select your target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **In-App Purchase**

### Step 6: Test with TestFlight
1. Archive your app (Product > Archive)
2. Upload to TestFlight
3. Test subscription flows with sandbox accounts
4. Create sandbox testers in App Store Connect > Users and Access > Sandbox Testers

### Step 7: Submit for Review
When submitting to App Review:
1. Provide test credentials if needed
2. Explain the premium features clearly
3. Ensure restore purchases works properly
4. Test all subscription states

## How It Works Without Backend

### Apple Handles Everything:
- **Transaction Storage**: Apple stores all transaction data
- **Verification**: Transactions are cryptographically signed
- **Sync**: Subscriptions sync via Apple ID across devices
- **Family Sharing**: Apple manages family sharing if enabled
- **Renewals**: Apple handles automatic renewals
- **Cancellation**: Users manage in iOS Settings

### Local Verification:
```swift
// The app verifies transactions locally
for await result in Transaction.currentEntitlements {
    let transaction = try checkVerified(result)
    // Transaction is cryptographically verified by Apple
}
```

### On App Launch:
1. App checks for active subscriptions via StoreKit 2
2. Updates local state (`isPremium` flag)
3. Features gate themselves based on this flag
4. User data stays on device with SwiftData

## Premium Feature Access

### Free Users Get:
- Unlimited text entries
- Up to 5 photos per entry
- "On This Day" memories
- Favoriting entries
- Rich text formatting

### Premium Users Get:
- Everything above, plus:
- Video support in entries
- Unlimited photos per entry
- Month review summaries
- Year highlights
- Future premium features

## Price Recommendations

Current prices in configuration:
- Monthly: $4.99/month
- Yearly: $39.99/year (saves ~33%)

Consider market research for your target audience. Journal apps typically range from $2.99-$9.99/month.

## Testing Checklist

- [ ] Test purchasing monthly subscription
- [ ] Test purchasing yearly subscription
- [ ] Test free trial period
- [ ] Test restore purchases
- [ ] Test adding 6th photo as free user (should show upgrade)
- [ ] Test adding video as free user (should show upgrade)
- [ ] Test accessing month review as free user (should show upgrade)
- [ ] Test accessing year highlights as free user (should show upgrade)
- [ ] Test that premium users can access all features
- [ ] Test subscription persistence after app restart
- [ ] Test on multiple devices with same Apple ID

## Important Notes

1. **Privacy First**: All user data stays on device, subscriptions managed by Apple
2. **No Server Needed**: Complete implementation with zero backend costs
3. **Family Sharing**: Can be enabled in App Store Connect
4. **Grace Period**: Apple provides automatic grace periods for failed payments
5. **Refunds**: Apple handles refund requests through their support

## Troubleshooting

### "Unable to load subscription options"
- Check StoreKit configuration is selected in scheme
- Verify product IDs match exactly
- Ensure app is running on simulator or device (not Mac Catalyst)

### Premium status not persisting
- Check that `updateSubscriptionStatus()` is called on app launch
- Verify transactions are being finished properly

### Can't test in simulator
- StoreKit 2 works in simulator with Configuration.storekit
- For TestFlight testing, use sandbox accounts

## Next Steps

1. **Customize Pricing**: Adjust prices based on your market research
2. **Add More Tiers**: Consider adding a lifetime purchase option
3. **Promotional Offers**: Set up promotional offers in App Store Connect
4. **Analytics**: Track conversion rates from paywall views
5. **A/B Testing**: Test different pricing and messaging

## Support

For StoreKit 2 documentation:
- https://developer.apple.com/documentation/storekit
- https://developer.apple.com/storekit/

For App Store Connect:
- https://help.apple.com/app-store-connect/
