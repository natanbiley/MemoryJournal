import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData();
    let modelContainer: ModelContainer;

    var context: ModelContext {
        modelContainer.mainContext;
    }
    
    private init() {
        let schema = Schema([Entry.self]);
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true);

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration]);
            insertSampleData();
            try context.save();
        } catch {
            fatalError("Failed to create model container: \(error)");
        }
    }

    private func insertSampleData() {
        for entry in Entry.sampleEntries {
            print("Adding sample entry: \(entry.bodyText) on \(entry.date)");
            context.insert(entry);
        }
    }
}