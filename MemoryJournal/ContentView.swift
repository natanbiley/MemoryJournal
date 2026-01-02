import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Entries", systemImage: "book.pages") {
                EntryList()
            }


            Tab("Insights", systemImage: "calendar") {
                
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
