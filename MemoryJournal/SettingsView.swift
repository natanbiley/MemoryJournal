import SwiftUI
import StoreKit

struct SettingsView: View {
    private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    if subscriptionManager.isPremium {
                        HStack {
                            Image(systemName: "rosette")
                                .foregroundStyle(.orange.gradient)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Member")
                                    .font(.headline)
                                
                                if let product = subscriptionManager.purchasedSubscriptions.first {
                                    Text(product.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Manage Subscription")
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption)
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "rosette")
                                            .foregroundStyle(.orange)
                                        Text("Upgrade to Premium")
                                            .font(.headline)
                                    }
                                    
                                    Text("Unlock videos, unlimited photos, and reviews")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Premium Features Section
                if !subscriptionManager.isPremium {
                    Section {
                        FeatureRow(
                            icon: "video.fill",
                            color: .blue,
                            title: "Video Memories",
                            description: "Add videos to entries"
                        )
                        
                        FeatureRow(
                            icon: "photo.stack.fill",
                            color: .green,
                            title: "Unlimited Photos",
                            description: "No limit on photos per entry"
                        )
                        
                        FeatureRow(
                            icon: "calendar.badge.checkmark",
                            color: .purple,
                            title: "Month Reviews",
                            description: "Monthly highlight summaries"
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            color: .orange,
                            title: "Year Highlights",
                            description: "Annual memory collections"
                        )
                    }
                }
                    
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Restore Purchases")
                            Spacer()
                        }
                    }
                    .disabled(subscriptionManager.isLoading)
                } header: {
                    Text("Subscription")
                }
                
                // App Information
                Section {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                        }
                    }
                    
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
