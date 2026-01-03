# Quick Testing Guide 🚀

## Test Right Now in 3 Steps:

### 1️⃣ Enable StoreKit Testing
```
Xcode Menu Bar:
Product → Scheme → Edit Scheme → Run → Options → 
StoreKit Configuration: Configuration.storekit
```

### 2️⃣ Run the App
Press ⌘R to run

### 3️⃣ Test These Flows:

#### Test Photo Limit (Free User):
1. Create new entry
2. Tap photo icon
3. Select 6+ photos
4. ✅ Should show "Photo Limit Reached" alert
5. ✅ Only 5 photos added
6. Tap "Upgrade to Premium"
7. ✅ See beautiful paywall

#### Test Video Lock (Free User):
1. Create new entry
2. Tap video icon (📹)
3. ✅ Should show "Premium Feature" alert
4. Tap "Upgrade to Premium"
5. ✅ See paywall

#### Test Month Review Lock:
1. Go to Review tab
2. Tap "December Review" section
3. ✅ Should show premium teaser with crown
4. Tap "Unlock Month Reviews"
5. ✅ See paywall

#### Test Year Highlights Lock:
1. Go to Review tab
2. Tap "Year Highlights" section
3. ✅ Should show premium teaser
4. Tap "Unlock Year Highlights"
5. ✅ See paywall

#### Test Purchase Flow:
1. Open paywall (from any locked feature)
2. ✅ See monthly ($4.99) and yearly ($39.99) options
3. Select yearly (notice "BEST VALUE" badge)
4. Tap "Start Free Trial"
5. ✅ StoreKit dialog appears
6. Confirm purchase (it's fake, no charge!)
7. ✅ Paywall dismisses
8. ✅ All features now unlocked!

#### Test Premium Features Work:
1. After "purchasing" subscription
2. Create new entry
3. ✅ Add 10+ photos (no limit!)
4. ✅ Add videos (works!)
5. Go to Review tab
6. ✅ See full month review content
7. ✅ See full year highlights

#### Test Settings:
1. Go to Settings tab
2. ✅ See "Premium Member" badge
3. Tap "Manage Subscription"
4. ✅ Opens to iOS Settings

#### Test Persistence:
1. Purchase subscription (if not done)
2. Close app (⌘W)
3. Reopen app (⌘R)
4. ✅ Still premium!
5. ✅ All features still unlocked

#### Test Restore Purchases:
1. Go to Settings
2. Tap "Restore Purchases"
3. ✅ Shows loading
4. ✅ Maintains premium status

## 🎯 What You Should See:

### Free User Experience:
- Can add up to 5 photos ✅
- Cannot add videos ❌
- Cannot access month review ❌
- Cannot access year highlights ❌
- Sees upgrade prompts with beautiful design
- Can see "On This Day" memories ✅

### Premium User Experience:
- Unlimited photos ✅
- Can add videos ✅
- Full month reviews ✅
- Full year highlights ✅
- Crown badge in Settings ✅
- All features unlocked ✅

## 🐛 Troubleshooting:

### "Unable to load subscription options"
→ Make sure StoreKit Configuration is set in scheme (Step 1)

### Purchases not working
→ Run on simulator or device (not Mac target)

### Premium status lost after restart
→ Should NOT happen - file a bug if it does

## 📱 Test on Real Device:

Same steps work on real iPhone/iPad connected to Mac!
StoreKit Configuration works for testing on device too.

## 🎉 When Everything Works:

You're ready to:
1. Set up products in App Store Connect
2. Archive and upload to TestFlight
3. Test with sandbox accounts
4. Submit for review
5. Launch! 🚀

---

**Current Test Prices:**
- Monthly: $4.99/month (7-day trial)
- Yearly: $39.99/year (7-day trial, best value)

**Product IDs:**
- `com.memoryjournal.premium.monthly`
- `com.memoryjournal.premium.yearly`

Change these in `SubscriptionManager.swift` if needed!
