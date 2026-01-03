import StoreKit
import SwiftUI

/// Manages in-app purchases and subscription status using StoreKit 2
@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    // Product identifiers - replace with your actual IDs from App Store Connect
    private let monthlyProductID = "com.memoryjournal.premium.monthly"
    private let yearlyProductID = "com.memoryjournal.premium.yearly"
    
    var products: [Product] = []
    var purchasedSubscriptions: [Product] = []
    var subscriptionGroupStatus: RenewalState?
    
    // Observable state for UI
    var isPremium: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        #if DEBUG
        // Skip StoreKit initialization in previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    /// Load available products from the App Store
    func loadProducts() async {
        #if DEBUG
        // Skip in previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        
        do {
            isLoading = true
            let productIDs = [monthlyProductID, yearlyProductID]
            print("🛒 Loading products with IDs: \(productIDs)")
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products: \(products.map { $0.id })")
            isLoading = false
        } catch {
            print("❌ Failed to load products: \(error)")
            print("   Make sure StoreKit Configuration is enabled in your scheme:")
            print("   Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration")
            errorMessage = "Failed to load subscription options"
            isLoading = false
        }
    }
    
    /// Purchase a subscription
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        errorMessage = nil
        
        let result = try await product.purchase()
        isLoading = false
        
        switch result {
        case .success(let verification):
            // Check if the transaction is verified
            let transaction = try checkVerified(verification)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Always finish a transaction
            await transaction.finish()
            
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases"
        }
        
        isLoading = false
    }
    
    /// Check if user has an active subscription
    func updateSubscriptionStatus() async {
        var activeSubscription: Product?
        
        // Check all active subscriptions
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if the product is one of our subscriptions
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                    break
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        // Update premium status
        await MainActor.run {
            self.isPremium = activeSubscription != nil
            if let subscription = activeSubscription {
                self.purchasedSubscriptions = [subscription]
            } else {
                self.purchasedSubscriptions = []
            }
        }
    }
    
    /// Listen for transaction updates
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to purchase()
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Deliver products to the user
                    await self.updateSubscriptionStatus()
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Verify a transaction to ensure it's legitimate
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Feature Access Methods
    
    /// Check if user can add videos (premium only)
    func canAddVideos() -> Bool {
        return isPremium
    }
    
    /// Check if user can add more photos
    func canAddMorePhotos(currentCount: Int) -> Bool {
        if isPremium {
            return true
        }
        return currentCount < 5
    }
    
    /// Check if user can access review features
    func canAccessReviews() -> Bool {
        return isPremium
    }
    
    /// Get remaining free photos
    func remainingFreePhotos(currentCount: Int) -> Int {
        if isPremium {
            return Int.max
        }
        return max(0, 5 - currentCount)
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}

// MARK: - Renewal State
enum RenewalState {
    case subscribed
    case expired
    case inBillingRetryPeriod
    case inGracePeriod
    case revoked
}
