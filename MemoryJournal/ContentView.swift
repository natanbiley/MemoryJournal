import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Entries", systemImage: "book") {
                EntryList()
            }


            Tab("Calendar", systemImage: "calendar") {
                
            }


            Tab("Settings", systemImage: "gear") {
                
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
