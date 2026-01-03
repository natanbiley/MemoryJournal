import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Entries", systemImage: "book.badge.plus") {
                EntryList()
            }


            Tab("Review", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                ReviewView()
            }


            Tab("Account", systemImage: "person.circle") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
