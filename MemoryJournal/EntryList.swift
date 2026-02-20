import SwiftUI
import SwiftData

struct EntryList: View {

    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @Environment(\.modelContext) private var context
    @State private var selection = Set<PersistentIdentifier>()
    @State private var editMode: EditMode = .inactive
    @State private var searchText = ""
    @State private var showWelcomeSheet = false
    @State private var isWelcomeSheetDismissed = false
    @State private var showFavoritesOnly = false
    @State private var showMonthPicker = false
    @State private var scrollToMonth: String?

    // Editor presentation state - using wrapper for fullScreenCover(item:)
    @State private var editorPresentation: EditorPresentation?
    
    // Glass button style with fallback for iOS < 26
    private var glassButtonStyle: some PrimitiveButtonStyle {
        if #available(iOS 26.0, *) {
            return AnyPrimitiveButtonStyle(.glass)
        } else {
            return AnyPrimitiveButtonStyle(.bordered)
        }
    }
    
    // Glass prominent button style with fallback for iOS < 26
    private var glassProminentButtonStyle: some PrimitiveButtonStyle {
        if #available(iOS 26.0, *) {
            return AnyPrimitiveButtonStyle(.glassProminent)
        } else {
            return AnyPrimitiveButtonStyle(.borderedProminent)
        }
    }
    
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
                Text("Welcome to DayScribe!")
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
        HStack {
            Text(entry.date, format: .dateTime.day()).bold().frame(width: 30)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.bodyText)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .padding(.leading, 5)

                // Media count footer
                if !entry.photos.isEmpty || !entry.videos.isEmpty {
                    HStack(spacing: 8) {
                        if !entry.photos.isEmpty {
                            HStack(spacing: 2) {
                                    Image(systemName: "photo")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                Text("\(entry.photos.count) photos")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                        if !entry.videos.isEmpty {
                            HStack(spacing: 2) {
                                    Image(systemName: "video.fill")
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                Text("\(entry.videos.count) videos")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 5)
                }
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
                    editorPresentation = EditorPresentation(entryID: entry.persistentModelID)
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
    
    private func mainListView(scrollProxy: ScrollViewProxy) -> some View {
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
                .id(monthYear)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search entries")
        .onChange(of: scrollToMonth) { _, newValue in
            if let month = newValue {
                withAnimation {
                    scrollProxy.scrollTo(month, anchor: .top)
                }
                scrollToMonth = nil
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if editMode == .inactive {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    Button(action: {
                        showWelcomeSheet = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                    .buttonStyle(glassButtonStyle)

                    Button(action: {
                        withAnimation {
                            showFavoritesOnly.toggle()
                        }
                    }) {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(showFavoritesOnly ? .red : .primary)
                    }
                    .buttonStyle(glassButtonStyle)

                    Button(action: {
                        showMonthPicker = true
                    }) {
                        Image(systemName: "calendar")
                            .font(.title3)
                    }
                    .buttonStyle(glassButtonStyle)
                }
            }
        }
        
        if editMode == .active && !selection.isEmpty {
            ToolbarItem {
                Button {
                    // Check if all selected entries are favorited
                    let allFavorited = selection.allSatisfy { entryID in
                        if let entry = context.model(for: entryID) as? Entry {
                            return entry.isFavorite
                        }
                        return false
                    }
                    
                    // If all are favorited, unfavorite all; otherwise, favorite all
                    for entryID in selection {
                        if let entry = context.model(for: entryID) as? Entry {
                            entry.isFavorite = !allFavorited
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
                .buttonStyle(glassButtonStyle)
            }
            
            ToolbarItem {
                Button(role: .destructive) {
                    for entryID in selection {
                        if let entry = context.model(for: entryID) as? Entry {
                            // Delete media files from disk
                            MediaStorageManager.shared.deleteAllMedia(for: entry.entryID)
                            // Delete entry from SwiftData (cascade deletes MediaItem records)
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
                .buttonStyle(glassButtonStyle)
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
                    .foregroundColor(editMode == .active ? .blue : .primary)
            }
        }
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    editorPresentation = EditorPresentation(entryID: nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 46, height: 56)
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .buttonStyle(glassProminentButtonStyle)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ZStack {
                    if filteredEntries.isEmpty && searchText.isEmpty && !showFavoritesOnly {
                        emptyStateView
                    } else if filteredEntries.isEmpty && !searchText.isEmpty {
                        emptySearchView
                    } else if filteredEntries.isEmpty && showFavoritesOnly {
                        emptyFavoritesView
                    }

                    mainListView(scrollProxy: scrollProxy)
                        .toolbar { toolbarContent }
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarBackground(.white, for: .navigationBar)
                        .environment(\.editMode, $editMode)

                    floatingAddButton
                }
            }
            .navigationTitle("Entries")
            .fullScreenCover(item: $editorPresentation) { presentation in
                EntryEditor(initialEntryID: presentation.entryID)
            }
            .sheet(isPresented: $showWelcomeSheet) {
                WelcomeView(isWelcomeSheetDismissed: $isWelcomeSheetDismissed)
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(
                    availableMonths: groupedEntries.map { $0.0 },
                    selectedMonth: $scrollToMonth
                )
            }
            .onAppear {
                if entries.isEmpty && searchText.isEmpty && !showFavoritesOnly && !isWelcomeSheetDismissed {
                    showWelcomeSheet = true
                }
            }
            .onDisappear {
                isWelcomeSheetDismissed = true
            }
        }
    }
}

// Welcome Screen View
struct WelcomeView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isWelcomeSheetDismissed: Bool

    @State private var reminderManager = ReminderManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Text("Welcome to DayScribe!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 0)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(
                            icon: "pencil.and.outline",
                            color: .blue,
                            title: "Write about your day",
                            description: "What did you do? Who did you see? How did you feel? Write down funny moments, interactions, ideas, get creative and have fun!"
                        )

                        FeatureRow(
                            icon: "photo.on.rectangle.angled",
                            color: .green,
                            title: "Add Photos & Videos",
                            description: "Capture your memories visually by attaching photos and videos to your entries"
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
                            title: "Review Highlights from the past",
                            description: "Get monthly and yearly reminders of your favorite memories"
                        )
                        FeatureRow(
                            icon: "shield.checkerboard",
                            color: .purple,
                            title: "Data Privacy",
                            description: "All your data is private and stored only on your device"
                        )
                        FeatureRow(
                            icon: "plus.circle.fill",
                            color: .blue,
                            title: "Tap the + button to get started!",
                            description: ""
                        )
                    }
                    .padding(.horizontal, 20)

                    // Daily Reminder Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Reminders")
                            .font(.headline)

                        Toggle("Remind me to journal", isOn: Binding(
                            get: { reminderManager.isEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        let status = await reminderManager.checkPermissionStatus()
                                        if status == .notDetermined {
                                            let granted = await reminderManager.requestPermission()
                                            if granted {
                                                reminderManager.isEnabled = true
                                            }
                                        } else if status == .authorized {
                                            reminderManager.isEnabled = true
                                        }
                                    }
                                } else {
                                    reminderManager.isEnabled = false
                                }
                            }
                        ))

                        if reminderManager.isEnabled {
                            DatePicker(
                                "Reminder time",
                                selection: $reminderManager.reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("About DayScribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        reminderManager.hasSeenOnboarding = true
                        isWelcomeSheetDismissed = true
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Editor Presentation Wrapper
struct EditorPresentation: Identifiable {
    let id = UUID()
    let entryID: PersistentIdentifier?
}

// MARK: - Month Picker View
struct MonthPickerView: View {
    let availableMonths: [String] // Format: "MMMM yyyy"
    @Binding var selectedMonth: String?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMonthName: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let years = availableMonths.compactMap { formatter.date(from: $0) }
            .map { Calendar.current.component(.year, from: $0) }
        return Array(Set(years)).sorted(by: >)
    }

    private var monthsForSelectedYear: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return availableMonths.filter { month in
            if let date = formatter.date(from: month) {
                return Calendar.current.component(.year, from: date) == selectedYear
            }
            return false
        }.compactMap { month in
            formatter.date(from: month).map {
                Calendar.current.monthSymbols[Calendar.current.component(.month, from: $0) - 1]
            }
        }
    }

    private var isValidSelection: Bool {
        monthsForSelectedYear.contains(selectedMonthName)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if availableMonths.isEmpty {
                    Text("No entries yet")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    HStack(spacing: 0) {
                        Picker("Month", selection: $selectedMonthName) {
                            ForEach(monthsForSelectedYear, id: \.self) { month in
                                Text(month).tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        Picker("Year", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Jump to Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Go") {
                        selectedMonth = "\(selectedMonthName) \(selectedYear)"
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                    .disabled(!isValidSelection)
                }
            }
            .onAppear {
                initializeSelection()
            }
            .onChange(of: selectedYear) { _, _ in
                // Auto-select first available month when year changes
                if !monthsForSelectedYear.contains(selectedMonthName),
                   let firstMonth = monthsForSelectedYear.first {
                    selectedMonthName = firstMonth
                }
            }
        }
        .presentationDetents([.height(280)])
    }

    private func initializeSelection() {
        if let first = availableMonths.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            if let date = formatter.date(from: first) {
                selectedMonthName = Calendar.current.monthSymbols[Calendar.current.component(.month, from: date) - 1]
                selectedYear = Calendar.current.component(.year, from: date)
            }
        }
    }
}

// MARK: - Button Style Wrapper
struct AnyPrimitiveButtonStyle: PrimitiveButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    init<S: PrimitiveButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

#Preview {
    EntryList()
        .modelContainer(SampleData.shared.modelContainer)
}
