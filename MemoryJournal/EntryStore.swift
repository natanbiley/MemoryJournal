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
}
