# Quick Fix: "Unable to load subscription options"

## The Problem
The app can't find the subscription products because the StoreKit Configuration file isn't enabled.

## The Solution (Takes 30 seconds)

### Step 1: Open Scheme Settings
In Xcode menu bar, click:
**Product** → **Scheme** → **Edit Scheme...**

(Or press: **⌘ + <** )

### Step 2: Enable StoreKit Configuration
1. In the left sidebar, select **Run**
2. Click the **Options** tab at the top
3. Find **StoreKit Configuration** dropdown
4. Select **Configuration.storekit**
5. Click **Close**

### Step 3: Run the App
Press **⌘R** to run the app

### Step 4: Test
1. Go to Settings tab
2. Tap "Upgrade to Premium"
3. You should now see the subscription options!

## What This Does
- Enables StoreKit testing mode
- Uses fake products from Configuration.storekit
- No real money charges during testing
- Simulates the real subscription flow

## Verification
Check the Xcode console when you open the paywall. You should see:
```
🛒 Loading products with IDs: ["com.memoryjournal.premium.monthly", "com.memoryjournal.premium.yearly"]
✅ Loaded 2 products: ["com.memoryjournal.premium.monthly", "com.memoryjournal.premium.yearly"]
```

If you still see errors, the console will tell you what's wrong.

## Still Not Working?

### Check These:
1. ✅ Configuration.storekit file exists in your project
2. ✅ File is included in your target (select it, check right sidebar)
3. ✅ Running on iOS Simulator or Device (not Mac)
4. ✅ Clean build folder (Product → Clean Build Folder or ⌘⇧K)

### Alternative: Use Sandbox Testing
If StoreKit Configuration doesn't work:
1. Create sandbox tester account in App Store Connect
2. Sign out of App Store on device
3. Run app and test with sandbox account

---

**After this setup, all subscription features will work perfectly for testing!** 🚀
