import SwiftUI
import SwiftData

@main
struct MemoryJournalApp: App {
    @State private var showReminderOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Entry.self, MediaItem.self])
                .onAppear {
                    if !ReminderManager.shared.hasSeenOnboarding {
                        showReminderOnboarding = true
                    }
                }
                .sheet(isPresented: $showReminderOnboarding) {
                    ReminderOnboardingView()
                        .interactiveDismissDisabled()
                }
        }
    }
}
