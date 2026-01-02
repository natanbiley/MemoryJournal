import SwiftUI
import SwiftData
@main
struct MemoryJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().modelContainer(for: [Entry.self])
        }
    }
}
