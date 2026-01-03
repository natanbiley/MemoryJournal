import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.orange.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "rosette")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange.gradient)
                        
                        Text("Memory Journal Premium")
                            .font(.title)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock the full journaling experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 20) {
                        PaywallFeatureRow(
                            icon: "video.fill",
                            color: .blue,
                            title: "Video Memories",
                            description: "Add videos to capture life's moments in motion"
                        )
                        
                        PaywallFeatureRow(
                            icon: "photo.stack.fill",
                            color: .green,
                            title: "Unlimited Photos",
                            description: "Add as many photos as you want per entry"
                        )
                        
                        PaywallFeatureRow(
                            icon: "calendar.badge.checkmark",
                            color: .purple,
                            title: "Month Reviews",
                            description: "Get beautiful summaries of your month"
                        )
                        
                        PaywallFeatureRow(
                            icon: "sparkles",
                            color: .orange,
                            title: "Year Highlights",
                            description: "Relive your best moments from any year"
                        )
                        
                        PaywallFeatureRow(
                            icon: "lock.shield.fill",
                            color: .blue,
                            title: "Privacy First",
                            description: "All data stays on your device, no account needed"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    
                    // Product selection
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if subscriptionManager.products.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            
                            Text("Unable to load subscription options")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Make sure StoreKit Configuration is enabled in your Xcode scheme")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                Task {
                                    await subscriptionManager.loadProducts()
                                }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                ProductButton(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id
                                ) {
                                    selectedProduct = product
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Subscribe button
                    if let product = selectedProduct {
                        Button {
                            Task {
                                do {
                                    _ = try await subscriptionManager.purchase(product)
                                    if subscriptionManager.isPremium {
                                        dismiss()
                                    }
                                } catch {
                                    showError = true
                                }
                            }
                        } label: {
                            HStack {
                                if subscriptionManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Start Free Trial")
                                        .bold()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange.gradient)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(subscriptionManager.isLoading)
                        .padding(.horizontal, 24)
                    }
                    
                    // Restore purchases
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.isPremium {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Legal text
                    Text("Subscription auto-renews unless cancelled. Cancel anytime in Settings.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 30)
                }
            }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = subscriptionManager.errorMessage {
                Text(error)
            } else {
                Text("Unable to complete purchase. Please try again.")
            }
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.products.first
            }
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)
                        
                        if isYearly {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.orange.gradient)
                                )
                        }
                    }
                    
                    Text(product.displayPrice + " / " + (isYearly ? "year" : "month"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if isYearly, let monthlyPrice = calculateMonthlyPrice() {
                        Text(monthlyPrice + " per month")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func calculateMonthlyPrice() -> String? {
        guard let subscription = product.subscription else { return nil }
        let period = subscription.subscriptionPeriod
        
        if period.unit == .year && period.value == 1 {
            // Simple calculation for display purposes
            let monthlyPrice = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            formatter.maximumFractionDigits = 2
            return formatter.string(from: monthlyPrice as NSDecimalNumber)
        }
        
        return nil
    }
}

#Preview {
    PaywallView()
}
