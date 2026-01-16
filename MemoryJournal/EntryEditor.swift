import SwiftUI
import SwiftData
import PhotosUI

struct EntryEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(EntryStore.self) private var store

    @State private var entryText = ""
    @State private var showDatePicker = false
    @State private var showDateConflictAlert = false
    @State private var conflictingEntry: Entry?
    @State private var datesWithEntries: Set<Date> = []
    @State private var temporarySelectedDate: Date = Date()
    @State private var isNewEntryFavorite = false
    @State private var isNavigating = false

    // Media state
    @State private var mediaViewModel = MediaViewModel()
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var videoPickerItems: [PhotosPickerItem] = []
    @FocusState private var isTextEditorFocused: Bool
    
    // Glass prominent button style with fallback for iOS < 26
    private var glassProminentButtonStyle: some PrimitiveButtonStyle {
        if #available(iOS 26.0, *) {
            return AnyPrimitiveButtonStyle(.glassProminent)
        } else {
            return AnyPrimitiveButtonStyle(.borderedProminent)
        }
    }
    
    var body: some View {
        @Bindable var store = store
        
        VStack(spacing: 0) {
            HStack {
                // Left: Save button
                Button(action: saveEntry) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Center: Date and navigation
                HStack {
                    if store.selectedEntryID != nil {
                        HStack(spacing: 20) {
                            Button(action: navigateToPreviousEntry) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(store.getPreviousEntry(context: context) != nil ? .blue : .gray)
                            }
                            .disabled(store.getPreviousEntry(context: context) == nil)
                            
                            if let entryDate = store.entryDate {
                                Text(entryDate, format: .dateTime.month(.abbreviated).day().year())
                                    .font(.headline)
                                    .bold()
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            Button(action: navigateToNextEntry) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(store.getNextEntry(context: context) != nil ? .blue : .gray)
                            }
                            .disabled(store.getNextEntry(context: context) == nil)
                        }
                    } else {
                        // Creating new entry - show date picker
                        if let entryDate = store.entryDate {
                            Text(entryDate, format: .dateTime.month(.abbreviated).day().year())
                                .font(.headline)
                                .bold()
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        } else {
                            Button("Select Date") {
                                temporarySelectedDate = store.entryDate ?? Date()
                                showDatePicker.toggle()
                            }
                            .buttonStyle(glassProminentButtonStyle)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Right: Favorite button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavoriteEntry() ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavoriteEntry() ? .red : .gray)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }.padding()
                .sheet(isPresented: $showDatePicker) {
                    DatePickerSheet(
                        temporarySelectedDate: $temporarySelectedDate,
                        datesWithEntries: datesWithEntries,
                        onDone: {
                            store.entryDate = temporarySelectedDate
                            showDatePicker = false
                            checkForExistingEntry(on: temporarySelectedDate)
                        },
                        onAppear: {
                            loadDatesWithEntries()
                        }
                    )
                }
                .alert("Date Already Has Entry", isPresented: $showDateConflictAlert) {
                    Button("Edit Existing Entry", role: .destructive) {
                        if let existingEntry = conflictingEntry {
                            store.showEditor(for: existingEntry.persistentModelID, context: context)
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        store.entryDate = nil
                    }
                } message: {
                    Text("This date already has an entry. Would you like to edit it?")
                }
            
            // Show loading view during navigation
            if isNavigating {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading entry...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
            } else {
                Divider()

                // Media sections (above text editor)
                VStack(spacing: 0) {
                    // Photo row
                    if !mediaViewModel.photos.isEmpty {
                        MediaScrollRow(
                            mediaItems: mediaViewModel.photos,
                            mediaType: .photo,
                            onTap: { item in
                                mediaViewModel.openGallery(for: item)
                            },
                            onDelete: { item in
                                if let entry = currentEntry {
                                    mediaViewModel.deleteMedia(item: item, entry: entry, context: context)
                                }
                            }
                        )
                    }

                    // Video row
                    if !mediaViewModel.videos.isEmpty {
                        MediaScrollRow(
                            mediaItems: mediaViewModel.videos,
                            mediaType: .video,
                            onTap: { item in
                                mediaViewModel.openGallery(for: item)
                            },
                            onDelete: { item in
                                if let entry = currentEntry {
                                    mediaViewModel.deleteMedia(item: item, entry: entry, context: context)
                                }
                            }
                        )
                    }
                }

                // Text editor
                TextEditor(text: $entryText)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .focused($isTextEditorFocused)
                    .onAppear {
                        loadInitialContent()
                        loadMedia()
                        // Open date picker by default for new entries
                        if store.selectedEntryID == nil && store.entryDate == nil {
                            temporarySelectedDate = Date()
                            showDatePicker = true
                        }
                    }
                    .onChange(of: store.selectedEntryID) { oldValue, newValue in
                        // Reload content when editing an entry
                        loadInitialContent()
                        loadMedia()
                    }

                // Media toolbar (above keyboard)
                if isTextEditorFocused {
                    MediaToolbar(
                        photoCount: mediaViewModel.photos.count,
                        videoCount: mediaViewModel.videos.count,
                        photoLimit: mediaViewModel.photoLimit,
                        videoLimit: mediaViewModel.videoLimit,
                        onAddPhoto: {
                            if mediaViewModel.checkPhotoLimitAndShowPaywall() {
                                showPhotoPicker = true
                            }
                        },
                        onAddVideo: {
                            if mediaViewModel.checkVideoLimitAndShowPaywall() {
                                showVideoPicker = true
                            }
                        },
                        onDismissKeyboard: {
                            isTextEditorFocused = false
                        }
                    )
                }
            }
        }
        // Photo picker
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $photoPickerItems,
            maxSelectionCount: max(0, mediaViewModel.photoLimit - mediaViewModel.photos.count),
            matching: .images
        )
        .onChange(of: photoPickerItems) { oldValue, newValue in
            handlePhotoSelection(newValue)
            photoPickerItems = []
        }
        // Video picker
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $videoPickerItems,
            maxSelectionCount: max(0, mediaViewModel.videoLimit - mediaViewModel.videos.count),
            matching: .videos
        )
        .onChange(of: videoPickerItems) { oldValue, newValue in
            handleVideoSelection(newValue)
            videoPickerItems = []
        }
        // Gallery
        .fullScreenCover(isPresented: $mediaViewModel.showGallery) {
            MediaGalleryView(
                mediaItems: mediaViewModel.galleryItems,
                selectedIndex: $mediaViewModel.selectedGalleryIndex
            )
        }
        // Paywall
        .sheet(isPresented: $mediaViewModel.showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Current Entry Helper

    private var currentEntry: Entry? {
        guard let entryID = store.selectedEntryID else { return nil }
        return context.model(for: entryID) as? Entry
    }

    // MARK: - Media Loading

    private func loadMedia() {
        mediaViewModel.loadMedia(from: currentEntry)
    }

    // MARK: - Photo Selection Handler

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        let viewModel = mediaViewModel
        let ctx = context

        guard let entry = currentEntry else {
            // For new entries, we need to save first
            saveEntryWithoutDismissingAndGetEntry { savedEntry in
                for item in items {
                    item.loadTransferable(type: Data.self) { result in
                        if case .success(let data) = result, let data = data,
                           let image = UIImage(data: data) {
                            Task { @MainActor in
                                viewModel.processAndSavePhotoDirectly(
                                    image: image,
                                    entry: savedEntry,
                                    context: ctx
                                )
                            }
                        }
                    }
                }
            }
            return
        }

        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data,
                   let image = UIImage(data: data) {
                    Task { @MainActor in
                        viewModel.processAndSavePhotoDirectly(
                            image: image,
                            entry: entry,
                            context: ctx
                        )
                    }
                }
            }
        }
    }

    // MARK: - Video Selection Handler

    private func handleVideoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        guard let entry = currentEntry else {
            // For new entries, we need to save first
            saveEntryWithoutDismissingAndGetEntry { savedEntry in
                for item in items {
                    loadAndProcessVideo(item: item, entry: savedEntry)
                }
            }
            return
        }

        for item in items {
            loadAndProcessVideo(item: item, entry: entry)
        }
    }

    private func loadAndProcessVideo(item: PhotosPickerItem, entry: Entry) {
        let viewModel = mediaViewModel
        let ctx = context

        item.loadTransferable(type: VideoTransferable.self) { result in
            if case .success(let video) = result, let video = video {
                Task { @MainActor in
                    await viewModel.processAndSaveVideoDirectly(
                        tempURL: video.url,
                        entry: entry,
                        context: ctx
                    )
                }
            }
        }
    }

    // MARK: - Save Entry and Get Reference

    private func saveEntryWithoutDismissingAndGetEntry(completion: @escaping (Entry) -> Void) {
        let plainText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let textToSave = plainText.isEmpty ? " " : plainText

        guard let date = store.entryDate else { return }

        let newEntry = Entry(bodyText: textToSave, date: date, isFavorite: isNewEntryFavorite)
        context.insert(newEntry)

        do {
            try context.save()
            store.selectedEntryID = newEntry.persistentModelID
            completion(newEntry)
        } catch {
            print("Error saving entry: \(error)")
        }
    }

    private func loadInitialContent() {
        isNewEntryFavorite = false
        entryText = store.entryText
    }
    
    private func saveEntry() {
        let plainText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Dismiss if no text is entered
        guard !plainText.isEmpty else {
            // If editing an existing entry that now has no content, delete it
            if let entryID = store.selectedEntryID {
                if let existingEntry = context.model(for: entryID) as? Entry {
                    context.delete(existingEntry)
                    try? context.save()
                }
            }
            store.dismissEditor()
            return
        }

        // Don't save if no date is selected
        guard let date = store.entryDate else {
            return
        }

        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry {
                // Update existing entry
                existingEntry.bodyText = plainText
                existingEntry.date = date
            }
        } else {
            // Create new entry
            let newEntry = Entry(bodyText: plainText, date: date, isFavorite: isNewEntryFavorite)
            context.insert(newEntry)
        }

        // Save the context
        do {
            try context.save()
        } catch {
            print("Error saving entry: \(error)")
        }

        store.dismissEditor()
    }
    
    private func checkForExistingEntry(on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate<Entry> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            if let existingEntry = results.first {
                conflictingEntry = existingEntry
                showDateConflictAlert = true
            }
        } catch {
            print("Error fetching entries: \(error)")
        }
    }
    
    private func isEditingCurrentEntry(date: Date) -> Bool {
        guard let entryID = store.selectedEntryID,
              let currentEntry = context.model(for: entryID) as? Entry else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDate(currentEntry.date, inSameDayAs: date)
    }
    
    private func loadDatesWithEntries() {
        let descriptor = FetchDescriptor<Entry>()
        
        do {
            let entries = try context.fetch(descriptor)
            let calendar = Calendar.current
            datesWithEntries = Set(entries.map { calendar.startOfDay(for: $0.date) })
        } catch {
            print("Error loading dates with entries: \(error)")
        }
    }
    
    private func navigateToPreviousEntry() {
        guard let previousEntry = store.getPreviousEntry(context: context) else {
            return
        }
        
        // Show loading overlay
        isNavigating = true
        
        // Save current entry before navigating
        saveEntryWithoutDismissing()
        
        // Load the previous entry
        store.showEditor(for: previousEntry.persistentModelID, context: context)
        loadInitialContent()
        
        // Hide loading overlay after content loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isNavigating = false
        }
    }
    
    private func navigateToNextEntry() {
        guard let nextEntry = store.getNextEntry(context: context) else {
            return
        }
        
        // Show loading overlay
        isNavigating = true
        
        // Save current entry before navigating
        saveEntryWithoutDismissing()
        
        // Load the next entry
        store.showEditor(for: nextEntry.persistentModelID, context: context)
        loadInitialContent()
        
        // Hide loading overlay after content loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isNavigating = false
        }
    }
    
    private func saveEntryWithoutDismissing() {
        let plainText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't save if no text
        guard !plainText.isEmpty else {
            return
        }

        // Don't save if no date
        guard let date = store.entryDate else {
            return
        }

        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry {
                // Update existing entry
                existingEntry.bodyText = plainText
                existingEntry.date = date
            }
        } else {
            // Create new entry
            let newEntry = Entry(bodyText: plainText, date: date, isFavorite: isNewEntryFavorite)
            context.insert(newEntry)
        }

        // Save the context
        do {
            try context.save()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
    
    private func toggleFavorite() {
        if let entryID = store.selectedEntryID,
           let existingEntry = context.model(for: entryID) as? Entry {
            // Toggle favorite for existing entry
            existingEntry.isFavorite.toggle()
            
            // Save the context
            do {
                try context.save()
            } catch {
                print("Error toggling favorite: \(error)")
            }
        } else {
            // Toggle favorite state for new entry
            isNewEntryFavorite.toggle()
        }
    }
    
    private func isFavoriteEntry() -> Bool {
        if let entryID = store.selectedEntryID,
           let existingEntry = context.model(for: entryID) as? Entry {
            // Return favorite status of existing entry
            return existingEntry.isFavorite
        } else {
            // Return favorite state for new entry
            return isNewEntryFavorite
        }
    }
}

struct DatePickerSheet: View {
    @Binding var temporarySelectedDate: Date
    let datesWithEntries: Set<Date>
    let onDone: () -> Void
    let onAppear: () -> Void
    
    var body: some View {
        VStack {
            CalendarView(
                selectedDate: $temporarySelectedDate,
                datesWithEntries: datesWithEntries
            )
            .padding()
            
            Spacer()
            HStack {
                Button("Done") {
                    onDone()
                }
                .padding()
                .bold()
            }
        }
        .presentationDetents([.height(500)])
        .interactiveDismissDisabled()
        .onAppear {
            onAppear()
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    let datesWithEntries: Set<Date>
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar grid
            let days = getDaysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasEntry: datesWithEntries.contains(calendar.startOfDay(for: date)),
                            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        // Generate 6 weeks worth of dates (42 days)
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEntry: Bool
    let isCurrentMonth: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .gray))
                .clipShape(Circle())
            
            if hasEntry {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            } else {
                Color.clear.frame(width: 6, height: 6)
            }
        }
    }
}

