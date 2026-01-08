import SwiftUI
import SwiftData
import Combine
import PhotosUI
import AVKit
import AVFoundation

struct EntryEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(EntryStore.self) private var store
    
    @StateObject private var richTextManager = RichTextManager()
    private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var showPhotoLimitAlert = false
    @State private var showDatePicker = false
    @State private var showDateConflictAlert = false
    @State private var conflictingEntry: Entry?
    @State private var datesWithEntries: Set<Date> = []
    @State private var temporarySelectedDate: Date = Date()
    @State private var toolbarHostingController: UIHostingController<RichTextToolbar>?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var cachedImages: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var selectedPhotoIndex: Int?
    @State private var showPhotoViewer = false
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var videoFilenames: [String] = []  // Store filenames of videos in Documents directory
    @State private var cachedVideoThumbnails: [Int: UIImage] = [:]
    @State private var showVideoPicker = false
    @State private var selectedVideoIndex: Int = 0
    @State private var showVideoPlayer = false
    @State private var currentVideoURL: URL?  // Direct URL for video playback
    @State private var isNewEntryFavorite = false
    @State private var isSavingVideos = false  // Show progress when saving large videos
    @State private var isNavigating = false  // Loading state for entry navigation
    
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
                Button(action: saveEntry) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                Spacer()
                
                // Navigation between entries (only when viewing an existing entry)
                if store.selectedEntryID != nil {
                    HStack(spacing: 20) {
                        Button(action: navigateToPreviousEntry) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(store.getPreviousEntry(context: context) != nil ? .blue : .gray)
                        }
                        .disabled(store.getPreviousEntry(context: context) == nil)
                        
                        if let entryDate = store.entryDate {
                            Text(entryDate, format: .dateTime.month(.wide).day().year())
                                .font(.headline)
                                .bold()
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
                        Text(entryDate, format: .dateTime.month(.wide).day().year())
                            .font(.headline)
                            .bold()
                    } else {
                        Button("Select Date") {
                            temporarySelectedDate = store.entryDate ?? Date()
                            showDatePicker.toggle()
                        }
                        .buttonStyle(glassProminentButtonStyle)
                    }
                }
                
                Spacer()
                
                // Favorite button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavoriteEntry() ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavoriteEntry() ? .red : .gray)
                }
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
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, maxSelectionCount: subscriptionManager.isPremium ? nil : 5, matching: .images)
                .onChange(of: selectedPhotos) { oldValue, newValue in
                    Task {
                        // Only process newly added items
                        let newItems = newValue.filter { !oldValue.contains($0) }
                        
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                photoData.append(data)
                                // Create downscaled thumbnail for gallery display
                                if let thumbnail = await createThumbnail(from: data, targetSize: CGSize(width: 200, height: 200)) {
                                    cachedImages.append(thumbnail)
                                } else if let uiImage = UIImage(data: data) {
                                    cachedImages.append(uiImage)
                                }
                            }
                        }
                    }
                }
                .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideos, maxSelectionCount: 5, matching: .videos)
                .onChange(of: selectedVideos) { oldValue, newValue in
                    Task {
                        // Only process newly added items
                        let newItems = newValue.filter { !oldValue.contains($0) }
                        
                        isSavingVideos = true
                        
                        for item in newItems {
                            // Save video directly to Documents directory
                            if let filename = await VideoStorageManager.shared.saveVideo(from: item) {
                                let currentIndex = videoFilenames.count
                                videoFilenames.append(filename)
                                // Generate thumbnail asynchronously
                                Task {
                                    if let thumbnail = await VideoStorageManager.shared.generateThumbnail(for: filename) {
                                        cachedVideoThumbnails[currentIndex] = thumbnail
                                    }
                                }
                            }
                        }
                        
                        isSavingVideos = false
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
                .alert("Photo Limit Reached", isPresented: $showPhotoLimitAlert) {
                    Button("Upgrade to Premium") {
                        showPaywall = true
                    }
                    Button("OK", role: .cancel) {
                        showPhotoPicker = true
                    }
                } message: {
                    Text("Free users can add up to 5 photos per entry. Upgrade to Premium for unlimited photos!")
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
                // Photo gallery
                if !photoData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(cachedImages.enumerated()), id: \.offset) { index, uiImage in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .contentShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        selectedPhotoIndex = index
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showPhotoViewer = true
                                        }
                                    }
                                
                                Button(action: {
                                    photoData.remove(at: index)
                                    cachedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6).clipShape(Circle()))
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 110)
            }
            
            // Video gallery
            if !videoFilenames.isEmpty || isSavingVideos {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(videoFilenames.enumerated()), id: \.offset) { index, filename in
                            ZStack(alignment: .topTrailing) {
                                ZStack {
                                    if let thumbnail = cachedVideoThumbnails[index] {
                                        Image(uiImage: thumbnail)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 100)
                                            .overlay {
                                                ProgressView()
                                            }
                                            .task {
                                                // Generate thumbnail if not cached
                                                if cachedVideoThumbnails[index] == nil {
                                                    if let thumbnail = await VideoStorageManager.shared.generateThumbnail(for: filename) {
                                                        cachedVideoThumbnails[index] = thumbnail
                                                    }
                                                }
                                            }
                                    }
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                        .shadow(radius: 3)
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    // Play video directly from file URL - no loading into memory!
                                    let videoURL = VideoStorageManager.shared.videoURL(for: filename)
                                    currentVideoURL = videoURL
                                    showVideoPlayer = true
                                }
                                
                                Button(action: {
                                    // Delete video file and remove from list
                                    Task {
                                        await VideoStorageManager.shared.deleteVideo(filename: filename)
                                    }
                                    videoFilenames.remove(at: index)
                                    cachedVideoThumbnails.removeValue(forKey: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6).clipShape(Circle()))
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                        
                        // Show loading indicator while saving videos
                        if isSavingVideos {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay {
                                    VStack(spacing: 4) {
                                        ProgressView()
                                        Text("Saving...")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 110)
            }
            
            Divider()
            
            // Rich Text Editor with toolbar as input accessory
            RichTextEditor(
                attributedText: $richTextManager.attributedText,
                selectedRange: $richTextManager.selectedRange,
                typingAttributes: $richTextManager.typingAttributes,
                inputAccessoryView: createToolbarView()
            )
            .onAppear {
                loadInitialContent()
                // Open date picker by default for new entries
                if store.selectedEntryID == nil && store.entryDate == nil {
                    temporarySelectedDate = Date()
                    showDatePicker = true
                }
            }
            .onChange(of: store.selectedEntryID) { oldValue, newValue in
                // Reload content when editing an entry
                loadInitialContent()
            }
            }
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            PhotoViewerView(photoData: photoData, currentIndex: selectedPhotoIndex ?? 0, isPresented: $showPhotoViewer)
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoURL = currentVideoURL {
                VideoPlayerView(videoURL: videoURL, isPresented: $showVideoPlayer)
            } else {
                // Fallback UI to avoid an empty white screen if URL isn't ready
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Preparing video…")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onChange(of: showVideoPlayer) { _, isShowing in
            if !isShowing {
                // Clear URL when player is dismissed
                currentVideoURL = nil
            }
        }
    }
    
    private func createToolbarView() -> UIView {
        let toolbar = RichTextToolbar(
            manager: richTextManager,
            showPhotoPicker: $showPhotoPicker,
            showVideoPicker: $showVideoPicker,
            onPhotoButtonTap: {
                if !subscriptionManager.isPremium && photoData.count >= 5 {
                    showPhotoLimitAlert = true
                } else {
                    showPhotoPicker = true
                }
            },
            onVideoButtonTap: {
                if subscriptionManager.canAddVideos() {
                    showVideoPicker = true
                } else {
                    showPaywall = true
                }
            }
        )
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.backgroundColor = UIColor.systemGray6
        
        // Set intrinsic size
        let size = hostingController.view.intrinsicContentSize
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
        hostingController.view.autoresizingMask = [.flexibleWidth]
        
        return hostingController.view
    }
    
    private func loadInitialContent() {
        // Clear existing data first
        photoData.removeAll()
        cachedImages.removeAll()
        selectedPhotos.removeAll()
        // Note: Don't delete video files here - they are permanent storage
        videoFilenames.removeAll()
        cachedVideoThumbnails.removeAll()
        selectedVideos.removeAll()
        isNewEntryFavorite = false
        
        // Load existing rich text if available
        if let html = store.entryHTML, !html.isEmpty,
           let manager = RichTextManager.fromHTML(html) {
            richTextManager.attributedText = manager.attributedText
        } else if !store.entryText.isEmpty {
            // Load plain text if no HTML available
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            richTextManager.attributedText = NSAttributedString(string: store.entryText, attributes: attributes)
        } else {
            // Clear text if no content
            richTextManager.attributedText = NSAttributedString(string: "", attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
        }
        
        // Load existing photos and videos if editing an entry
        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry {
                if let photos = existingEntry.photos {
                    photoData = photos
                    // Create downscaled thumbnails asynchronously for gallery display
                    Task {
                        var thumbnails: [UIImage] = []
                        for data in photos {
                            if let thumbnail = await createThumbnail(from: data, targetSize: CGSize(width: 200, height: 200)) {
                                thumbnails.append(thumbnail)
                            } else if let uiImage = UIImage(data: data) {
                                thumbnails.append(uiImage)
                            }
                        }
                        await MainActor.run {
                            cachedImages = thumbnails
                        }
                    }
                }
                // Load video filenames - instant, no data loading!
                if let filenames = existingEntry.videoFilenames {
                    videoFilenames = filenames
                    // Generate thumbnails asynchronously
                    for (index, filename) in filenames.enumerated() {
                        Task {
                            if let thumbnail = await VideoStorageManager.shared.generateThumbnail(for: filename) {
                                cachedVideoThumbnails[index] = thumbnail
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let plainText = richTextManager.getPlainText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Dismiss if no text, photos, or videos are entered
        guard !plainText.isEmpty || !photoData.isEmpty || !videoFilenames.isEmpty else {
            store.dismissEditor()
            return
        }
        
        // Don't save if no date is selected
        guard let date = store.entryDate else {
            return
        }
        
        let htmlString = richTextManager.getHTMLString()
        
        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry {
                // Delete old video files that are no longer referenced
                if let oldFilenames = existingEntry.videoFilenames {
                    let removedFilenames = Set(oldFilenames).subtracting(Set(videoFilenames))
                    Task {
                        await VideoStorageManager.shared.deleteVideos(filenames: Array(removedFilenames))
                    }
                }
                
                // Update existing entry
                existingEntry.bodyText = plainText
                existingEntry.bodyHTML = htmlString
                existingEntry.date = date
                existingEntry.photos = photoData.isEmpty ? nil : photoData
                existingEntry.videoFilenames = videoFilenames.isEmpty ? nil : videoFilenames
            }
        } else {
            // Create new entry
            let newEntry = Entry(bodyText: plainText, date: date, bodyHTML: htmlString, photos: photoData.isEmpty ? nil : photoData, videoFilenames: videoFilenames.isEmpty ? nil : videoFilenames, isFavorite: isNewEntryFavorite)
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
    
    // MARK: - Thumbnail Helpers
    
    /// Creates a downscaled thumbnail from image data for efficient gallery display
    private func createThumbnail(from imageData: Data, targetSize: CGSize) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
                return nil
            }
            
            let maxDimension = max(targetSize.width, targetSize.height) * UIScreen.main.scale
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return nil
            }
            
            return UIImage(cgImage: cgImage)
        }.value
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
        let plainText = richTextManager.getPlainText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't save if no text
        guard !plainText.isEmpty else {
            return
        }
        
        // Don't save if no date
        guard let date = store.entryDate else {
            return
        }
        
        let htmlString = richTextManager.getHTMLString()
        
        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry {
                // Delete old video files that are no longer referenced
                if let oldFilenames = existingEntry.videoFilenames {
                    let removedFilenames = Set(oldFilenames).subtracting(Set(videoFilenames))
                    Task {
                        await VideoStorageManager.shared.deleteVideos(filenames: Array(removedFilenames))
                    }
                }
                
                // Update existing entry
                existingEntry.bodyText = plainText
                existingEntry.bodyHTML = htmlString
                existingEntry.date = date
                existingEntry.photos = photoData.isEmpty ? nil : photoData
                existingEntry.videoFilenames = videoFilenames.isEmpty ? nil : videoFilenames
            }
        } else {
            // Create new entry
            let newEntry = Entry(bodyText: plainText, date: date, bodyHTML: htmlString, photos: photoData.isEmpty ? nil : photoData, videoFilenames: videoFilenames.isEmpty ? nil : videoFilenames, isFavorite: isNewEntryFavorite)
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

// MARK: - Photo Viewer
struct PhotoViewerView: View {
    let photoData: [Data]
    @State var currentIndex: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Photo viewer with swipe gesture
                TabView(selection: $currentIndex) {
                    ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            GeometryReader { geometry in
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Spacer()
                
                // Photo counter
                if photoData.count > 1 {
                    Text("\(currentIndex + 1) of \(photoData.count)")
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Video Player
struct VideoPlayerView: View {
    let videoURL: URL  // Direct file URL - no loading into memory!
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        cleanup()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .frame(height: 60)
                .background(Color.black.opacity(0.5))
                
                // Video player
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                        Text("Loading video...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupPlayer() {
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create player directly from file URL - instant, no loading into memory!
            let newPlayer = AVPlayer(url: videoURL)
            self.player = newPlayer
            newPlayer.play()
            
            print("▶️ Playing video directly from: \(videoURL.lastPathComponent)")
        } catch {
            print("❌ Error setting up audio session: \(error)")
        }
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        // Note: Don't delete the video file - it's permanent storage in Documents
    }
}
