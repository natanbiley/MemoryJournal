# Subscription Architecture Overview

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────┐
│                   Your App                       │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │      SubscriptionManager                 │   │
│  │      (Singleton, @Observable)            │   │
│  │                                          │   │
│  │  • isPremium: Bool                       │   │
│  │  • products: [Product]                   │   │
│  │  • purchasedSubscriptions: [Product]     │   │
│  │                                          │   │
│  │  Methods:                                │   │
│  │  • loadProducts()                        │   │
│  │  • purchase()                            │   │
│  │  • restorePurchases()                    │   │
│  │  • updateSubscriptionStatus()            │   │
│  │  • canAddVideos()                        │   │
│  │  • canAddMorePhotos()                    │   │
│  │  • canAccessReviews()                    │   │
│  └────────────┬─────────────────────────────┘   │
│               │                                  │
│               │ Uses                             │
│               ↓                                  │
│  ┌─────────────────────────────────────────┐   │
│  │         StoreKit 2 API                   │   │
│  │  • Product.products()                    │   │
│  │  • product.purchase()                    │   │
│  │  • Transaction.currentEntitlements       │   │
│  │  • Transaction.updates                   │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                      ↕
         [Verified Transactions]
                      ↕
┌─────────────────────────────────────────────────┐
│              Apple's Servers                     │
│                                                  │
│  • Store subscription data                       │
│  • Cryptographically sign transactions           │
│  • Sync across devices via Apple ID              │
│  • Handle renewals & billing                     │
│  • Manage family sharing                         │
│  • Process refunds                               │
└─────────────────────────────────────────────────┘
```

## 📊 Data Flow

### On App Launch:
```
1. SubscriptionManager.init()
   ↓
2. listenForTransactions() [background task]
   ↓
3. loadProducts() from App Store
   ↓
4. updateSubscriptionStatus()
   ↓
5. Check Transaction.currentEntitlements
   ↓
6. Verify each transaction (cryptographic check)
   ↓
7. Update isPremium flag
   ↓
8. UI updates automatically (@Observable)
```

### On Purchase:
```
1. User taps "Start Free Trial"
   ↓
2. purchase(product) called
   ↓
3. StoreKit shows system dialog
   ↓
4. User confirms (Face ID/Touch ID)
   ↓
5. Apple processes transaction
   ↓
6. Transaction returned to app
   ↓
7. Verify transaction signature
   ↓
8. updateSubscriptionStatus()
   ↓
9. isPremium = true
   ↓
10. transaction.finish() [always!]
   ↓
11. UI updates, features unlock
```

### On Feature Access:
```
User tries premium feature
   ↓
Check: subscriptionManager.canAddVideos()
   ↓
   ├─ true: Allow feature
   └─ false: Show paywall
```

## 🔐 Security Model

### Why No Backend Needed:

1. **Cryptographic Verification**:
   - Every transaction signed by Apple
   - JWS (JSON Web Signature) format
   - App verifies signature locally
   - Impossible to fake

2. **Apple ID Integration**:
   - Subscriptions tied to Apple ID
   - Automatic sync across devices
   - No need for your own accounts

3. **Local State**:
   - `isPremium` flag stored in memory
   - Rechecked on every app launch
   - Can't be manipulated (verified each time)

### Transaction Verification:
```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw StoreError.failedVerification
    case .verified(let safe):
        return safe  // ✅ Cryptographically verified by Apple
    }
}
```

## 🎨 UI Components

### Feature Gating Locations:

1. **EntryEditor.swift**:
   ```
   Photo Picker
   └─ maxSelectionCount: isPremium ? 20 : 5
   
   Photo Selection
   └─ if count > 5 && !isPremium → show alert
   
   Video Picker
   └─ if !canAddVideos() → show alert
   ```

2. **ReviewView.swift**:
   ```
   Month Review Button
   └─ if !canAccessReviews() → show paywall
   
   Month Review Content
   └─ if isPremium → show content
      else → show premium teaser
   
   Year Highlights Button
   └─ if !canAccessReviews() → show paywall
   
   Year Highlights Content
   └─ if isPremium → show content
      else → show premium teaser
   ```

3. **SettingsView.swift**:
   ```
   Subscription Section
   └─ if isPremium → show status & manage button
      else → show upgrade button
   
   Features List
   └─ if !isPremium → show what they're missing
   ```

## 📱 State Management

### Using @Observable (iOS 17+):
```swift
@Observable
class SubscriptionManager {
    var isPremium: Bool = false  // ← SwiftUI auto-updates!
}

// In views:
@State private var subscriptionManager = SubscriptionManager.shared

// UI automatically updates when isPremium changes!
```

### Singleton Pattern:
```swift
static let shared = SubscriptionManager()

// All views share same instance
// Consistent state across app
```

## 🔄 Lifecycle Events

### App Launch:
- Load products
- Check current entitlements
- Update premium status
- Start transaction listener

### App Backgrounded:
- Transaction listener keeps running
- Handles subscription changes
- Updates state when app returns

### App Terminated:
- Transaction listener stops
- On next launch: re-check everything
- Premium status restored

### Device Change:
- User logs in with Apple ID
- StoreKit syncs subscriptions
- App checks entitlements
- Premium status automatically restored

## 🧪 Testing Architecture

### Development:
```
Configuration.storekit
   ↓
StoreKit Testing Environment
   ↓
Fake transactions (free!)
   ↓
Full feature testing
```

### TestFlight:
```
Sandbox Account
   ↓
Real StoreKit environment
   ↓
Test transactions (free!)
   ↓
Production-like testing
```

### Production:
```
Real User Apple ID
   ↓
Real StoreKit environment
   ↓
Real transactions
   ↓
Real revenue! 💰
```

## 📈 Scaling Considerations

### Current Setup Handles:
- ✅ Unlimited users
- ✅ Multiple devices per user
- ✅ Family sharing
- ✅ App reinstalls
- ✅ Device upgrades
- ✅ iOS updates

### No Backend = No Costs:
- No server hosting
- No database
- No API costs
- No scaling issues
- Just Apple's infrastructure

### When You Might Need Backend:
- Cross-platform (Android, Web)
- Custom analytics
- User accounts
- Social features
- Advanced subscription logic

## 🎯 Best Practices Implemented

1. ✅ Always finish transactions
2. ✅ Verify all transactions
3. ✅ Listen for transaction updates
4. ✅ Check entitlements on launch
5. ✅ Handle errors gracefully
6. ✅ Provide restore purchases
7. ✅ Show clear pricing
8. ✅ Explain premium features
9. ✅ Make it easy to upgrade
10. ✅ Test thoroughly

## 🚀 Production Checklist

- [ ] Create products in App Store Connect
- [ ] Match product IDs exactly
- [ ] Add In-App Purchase capability
- [ ] Test with sandbox accounts
- [ ] Test restore purchases
- [ ] Test on multiple devices
- [ ] Test family sharing (if enabled)
- [ ] Prepare App Review notes
- [ ] Set up promotional images
- [ ] Plan launch pricing
- [ ] Monitor conversion rates
- [ ] Respond to reviews
- [ ] Iterate based on feedback

---

**This architecture is production-ready and scales automatically with Apple's infrastructure!** 🎉
