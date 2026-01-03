import SwiftUI
import SwiftData

@Observable
class EntryStore {
    var selectedEntryID: PersistentIdentifier?
    var isShowingEditor = false
    var entryText = ""
    var entryHTML: String? // Store HTML for rich text
    var entryDate: Date?
    
    func showEditor(for entryID: PersistentIdentifier? = nil, context: ModelContext) {
        selectedEntryID = entryID
        
        // Load entry data if editing existing entry
        if let entryID = entryID {
            // Try to fetch the entry, will return nil if not found
            let entry = context.model(for: entryID) as? Entry
            if let entry = entry {
                entryText = entry.bodyText
                entryHTML = entry.bodyHTML
                entryDate = entry.date
            } else {
                // Entry not found, reset to new entry
                entryText = ""
                entryHTML = nil
                entryDate = nil
                selectedEntryID = nil
            }
        } else {
            // Reset for new entry
            entryText = ""
            entryHTML = nil
            entryDate = nil
        }
        
        isShowingEditor = true
    }
    
    func dismissEditor() {
        isShowingEditor = false
        selectedEntryID = nil
        entryText = ""
        entryHTML = nil
        entryDate = nil
    }
    
    func getPreviousEntry(context: ModelContext) -> Entry? {
        guard let currentEntryID = selectedEntryID,
              let currentEntry = context.model(for: currentEntryID) as? Entry else {
            return nil
        }
        
        let descriptor = FetchDescriptor<Entry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allEntries = try context.fetch(descriptor)
            guard let currentIndex = allEntries.firstIndex(where: { $0.persistentModelID == currentEntryID }) else {
                return nil
            }
            
            // Previous entry is the one after current index (since sorted reverse)
            let previousIndex = currentIndex + 1
            guard previousIndex < allEntries.count else {
                return nil
            }
            
            return allEntries[previousIndex]
        } catch {
            print("Error fetching entries: \(error)")
            return nil
        }
    }
    
    func getNextEntry(context: ModelContext) -> Entry? {
        guard let currentEntryID = selectedEntryID,
              let currentEntry = context.model(for: currentEntryID) as? Entry else {
            return nil
        }
        
        let descriptor = FetchDescriptor<Entry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allEntries = try context.fetch(descriptor)
            guard let currentIndex = allEntries.firstIndex(where: { $0.persistentModelID == currentEntryID }) else {
                return nil
            }
            
            // Next entry is the one before current index (since sorted reverse)
            let nextIndex = currentIndex - 1
            guard nextIndex >= 0 else {
                return nil
            }
            
            return allEntries[nextIndex]
        } catch {
            print("Error fetching entries: \(error)")
            return nil
        }
    }
}
