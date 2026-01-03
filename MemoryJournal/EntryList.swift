import SwiftUI
import SwiftData

struct EntryList: View {
    
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @Environment(\.modelContext) private var context
    @State private var store = EntryStore()
    @State private var selection = Set<PersistentIdentifier>()
    @State private var editMode: EditMode = .inactive
    @State private var searchText = ""
    @State private var showWelcomeSheet = false
    @State private var showFavoritesOnly = false
    
    // Filter entries based on search text
    private var filteredEntries: [Entry] {
        var result = entries
        
        // Apply favorites filter
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.bodyText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    // Group entries by month
    private var groupedEntries: [(String, [Entry])] {
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
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                Text("Welcome to Memory Book!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Start capturing your precious moments and memories today")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.gray.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 10) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("No entries match '\(searchText)'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.red.opacity(0.6))
            }
            
            VStack(spacing: 10) {
                Text("No Favorited Entries Yet")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func entryRowView(_ entry: Entry) -> some View {
        HStack{
            Text(entry.date, format: .dateTime.day()).bold().frame(width: 30)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text(String(entry.bodyText.prefix(70)) + "...").padding(.leading, 5)
                HStack(spacing: 8) {
                    if let photos = entry.photos, !photos.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("\(photos.count) photo\(photos.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let videos = entry.videos, !videos.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text("\(videos.count) video\(videos.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 5)
            }
            Spacer()
            if entry.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onLongPressGesture {
            editMode = .active
            selection.insert(entry.persistentModelID)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if editMode == .inactive {
                    store.showEditor(for: entry.persistentModelID, context: context)
                } else {
                    if selection.contains(entry.persistentModelID) {
                        selection.remove(entry.persistentModelID)
                    } else {
                        selection.insert(entry.persistentModelID)
                    }
                }
            }
        )
    }
    
    private var mainListView: some View {
        List(selection: $selection) {
            ForEach(groupedEntries, id: \.0) { monthYear, monthEntries in
                Section(header: Text(monthYear)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                ) {
                    ForEach(monthEntries) { entry in
                        entryRowView(entry)
                    }
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search entries")
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 12) {
                Button(action: {
                    showWelcomeSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                }
                .buttonStyle(.glass)
                
                Button(action: {
                    withAnimation {
                        showFavoritesOnly.toggle()
                    }
                }) {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(showFavoritesOnly ? .red : .primary)
                }
                .buttonStyle(.glass)
            }
        }
        
        if editMode == .active && !selection.isEmpty {
            ToolbarItem {
                Button {
                    for entryID in selection {
                        if let entry = context.model(for: entryID) as? Entry {
                            entry.isFavorite.toggle()
                        }
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Error saving context after favoriting: \(error)")
                    }
                } label: {
                    Image(systemName: "heart.fill")
                }
                .foregroundColor(.red)
                .buttonStyle(.glass)
            }
            
            ToolbarItem {
                Button(role: .destructive) {
                    for entryID in selection {
                        if let entry = context.model(for: entryID) as? Entry {
                            context.delete(entry)
                        }
                    }
                    selection.removeAll()
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
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    store.showEditor(context: context)
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 60)
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .buttonStyle(.glassProminent)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredEntries.isEmpty && searchText.isEmpty && !showFavoritesOnly {
                    emptyStateView
                } else if filteredEntries.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else if filteredEntries.isEmpty && showFavoritesOnly {
                    emptyFavoritesView
                }
                
                mainListView
                    .toolbar { toolbarContent }
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarBackground(.white, for: .navigationBar)
                    .environment(\.editMode, $editMode)
                
                floatingAddButton
            }
            .navigationTitle("Entries")
            .fullScreenCover(isPresented: $store.isShowingEditor) {
                EntryEditor()
                    .environment(store)
            }
            .sheet(isPresented: $showWelcomeSheet) {
                WelcomeView()
            }
        }
    }
}

// Welcome Screen View
struct WelcomeView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(
                            icon: "pencil.and.outline",
                            color: .blue,
                            title: "Write about your day",
                            description: "What did you do? Who did you see? How did you feel? Write down funny moments, interactions, ideas, have fun!"
                        )
                        
                        FeatureRow(
                            icon: "photo.on.rectangle",
                            color: .green,
                            title: "Add Photos & Videos",
                            description: ""
                        )
                        
                        FeatureRow(
                            icon: "heart.fill",
                            color: .red,
                            title: "Favorite Entries",
                            description: "Mark special moments as favorites for quick access"
                        )

                        FeatureRow(
                            icon: "calendar",
                            color: .orange,
                            title: "Review your Highlights from the past",
                            description: ""
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("About Memory Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EntryList()
        .modelContainer(SampleData.shared.modelContainer)
}