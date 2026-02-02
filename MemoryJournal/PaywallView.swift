import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private let productIDs = ["DayScribePremiumMonthly", "DayScribePremiumYearly"]

    var body: some View {
        SubscriptionStoreView(productIDs: productIDs) {
            PaywallMarketingContent()
        }
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .redeemCode)
        .subscriptionStorePolicyDestination(url: URL(string: "https://natanbiley.github.io/MemoryJournal/")!, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, for: .termsOfService)
        .background {
            LinearGradient(
                colors: [.orange.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success(_)) = result {
                dismiss()
            }
        }
    }
}

struct PaywallMarketingContent: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rosette")
                .font(.system(size: 50))
                .foregroundStyle(.orange.gradient)

            Text("DayScribe Premium")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                FeatureItem(icon: "video.fill", color: .blue, text: "Video Memories")
                FeatureItem(icon: "photo.stack.fill", color: .green, text: "Unlimited Photos")
                FeatureItem(icon: "calendar.badge.checkmark", color: .purple, text: "Month Reviews")
                FeatureItem(icon: "sparkles", color: .orange, text: "Year Highlights")
                FeatureItem(icon: "square.and.arrow.up.fill", color: .teal, text: "Export Journals")
            }
        }
        .padding(.top, 30)
    }
}

private struct FeatureItem: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color.gradient)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    PaywallView()
}
