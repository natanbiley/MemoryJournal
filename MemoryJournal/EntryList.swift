import SwiftUI
import SwiftData

struct EntryList: View {
    
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @Environment(\.modelContext) private var context
    @State private var store = EntryStore()
    @State private var selection = Set<PersistentIdentifier>()
    @State private var editMode: EditMode = .inactive
    @State private var searchText = ""
    
    // Filter entries based on search text
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { entry in
                entry.bodyText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Group entries by month
    private var groupedEntries: [(String, [Entry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.date)
        }
        
        // Sort by date (newest first)
        return grouped.sorted { first, second in
            guard let date1 = formatter.date(from: first.key),
                  let date2 = formatter.date(from: second.key) else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List(selection: $selection) {
                    ForEach(groupedEntries, id: \.0) { monthYear, monthEntries in
                        Section(header: Text(monthYear)
                            .font(.title2)
                            .foregroundColor(.blue)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ) {
                            ForEach(monthEntries) { entry in
                                HStack{
                                    Text(entry.date, format: .dateTime.day()).bold().frame(width: 30)
                                    Divider()
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(entry.bodyText.prefix(70)) + "...").padding(.leading, 5)
                                        if let photos = entry.photos, !photos.isEmpty {
                                            HStack(spacing: 4) {
                                                Image(systemName: "photo.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                Text("\(photos.count) photo\(photos.count > 1 ? "s" : "")")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.leading, 5)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onLongPressGesture {
                                    // Enter edit mode and select this item
                                    editMode = .active
                                    selection.insert(entry.persistentModelID)
                                }
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        if editMode == .inactive {
                                            store.showEditor(for: entry.persistentModelID, context: context)
                                        } else {
                                            // Toggle selection in edit mode
                                            if selection.contains(entry.persistentModelID) {
                                                selection.remove(entry.persistentModelID)
                                            } else {
                                                selection.insert(entry.persistentModelID)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .listSectionSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search entries")
                .toolbar {
                    if editMode == .active && !selection.isEmpty {
                        Button(role: .destructive) {
                            // Delete selected entries
                            for entryID in selection {
                                if let entry = context.model(for: entryID) as? Entry {
                                    context.delete(entry)
                                }
                            }
                            selection.removeAll()
                            // Save the context to persist changes
                            do {
                                try context.save()
                            } catch {
                                print("Error saving context after deletion: \(error)")
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .foregroundColor(.red)
                        .buttonStyle(.glass)
                    }
                    Button(action: {
                        withAnimation {
                            editMode = editMode == .inactive ? .active : .inactive
                            if editMode == .inactive {
                                selection.removeAll()
                            }
                        }
                    }) {
                        Text(editMode == .inactive ? "Edit" : "Done")
                    }
                    .buttonStyle(.glass)
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.white, for: .navigationBar)
                .environment(\.editMode, $editMode)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // // Check if an entry for today already exists
                            // let calendar = Calendar.current
                            // let today = calendar.startOfDay(for: Date())
                            
                            // if let todayEntry = entries.first(where: { entry in
                            //     calendar.isDate(entry.date, inSameDayAs: today)
                            // }) {
                            //     // Open existing today's entry
                            //     store.showEditor(for: todayEntry.persistentModelID, context: context)
                            // } else {
                            //     // Create new entry
                            // }
                                store.showEditor(context: context)
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 60)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .buttonStyle(.glass)
                    }
                }
            }
            .navigationTitle("Entries")
            .fullScreenCover(isPresented: $store.isShowingEditor) {
                EntryEditor()
                    .environment(store)
            }
        }
    }
}

#Preview {
    EntryList()
        .modelContainer(SampleData.shared.modelContainer)
}