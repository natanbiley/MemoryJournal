import SwiftUI
import SwiftData
import Combine
import PhotosUI

struct EntryEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(EntryStore.self) private var store
    
    @StateObject private var richTextManager = RichTextManager()
    @State private var showDatePicker = false
    @State private var showDateConflictAlert = false
    @State private var conflictingEntry: Entry?
    @State private var datesWithEntries: Set<Date> = []
    @State private var toolbarHostingController: UIHostingController<RichTextToolbar>?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var cachedImages: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var selectedPhotoIndex: Int?
    @State private var showPhotoViewer = false
    
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
                if let entryDate = store.entryDate {
                    Text(entryDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                        .bold()
                } else {
                    Button("Select Date") {
                        showDatePicker.toggle()
                    }
                    .buttonStyle(.glassProminent)
                }
                Spacer()
            }.padding()
                .sheet(isPresented: $showDatePicker) {
                    VStack {
                        CalendarView(
                            selectedDate: Binding(
                                get: { store.entryDate ?? Date() },
                                set: { store.entryDate = $0 }
                            ),
                            datesWithEntries: datesWithEntries
                        )
                        .padding()
                        
                        Spacer()
                        HStack {
                            Button("Done") {
                                let selectedDate = store.entryDate ?? Date()
                                store.entryDate = selectedDate
                                showDatePicker = false
                                checkForExistingEntry(on: selectedDate)
                            }
                            .padding()
                            .bold()
                        }
                    }
                    .presentationDetents([.height(500)])
                    .onAppear {
                        loadDatesWithEntries()
                    }
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
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, maxSelectionCount: 10, matching: .images)
                .onChange(of: selectedPhotos) { oldValue, newValue in
                    Task {
                        photoData.removeAll()
                        cachedImages.removeAll()
                        for item in newValue {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                photoData.append(data)
                                if let uiImage = UIImage(data: data) {
                                    cachedImages.append(uiImage)
                                }
                            }
                        }
                    }
                }
            
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
                                    .onTapGesture {
                                        selectedPhotoIndex = index
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showPhotoViewer = true
                                        }
                                    }
                                
                                Button(action: {
                                    photoData.remove(at: index)
                                    cachedImages.remove(at: index)
                                    selectedPhotos.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6).clipShape(Circle()))
                                }
                                .padding(4)
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
            }
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            PhotoViewerView(photoData: photoData, currentIndex: selectedPhotoIndex ?? 0, isPresented: $showPhotoViewer)
        }
    }
    
    private func createToolbarView() -> UIView {
        let toolbar = RichTextToolbar(manager: richTextManager, showPhotoPicker: $showPhotoPicker)
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.backgroundColor = UIColor.systemGray6
        
        // Set intrinsic size
        let size = hostingController.view.intrinsicContentSize
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
        hostingController.view.autoresizingMask = [.flexibleWidth]
        
        return hostingController.view
    }
    
    private func loadInitialContent() {
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
        }
        
        // Load existing photos if editing an entry
        if let entryID = store.selectedEntryID {
            let existingEntry = context.model(for: entryID) as? Entry
            if let existingEntry = existingEntry,
               let photos = existingEntry.photos {
                photoData = photos
                // Cache the images on load
                cachedImages = photos.compactMap { UIImage(data: $0) }
            }
        }
    }
    
    private func saveEntry() {
        let plainText = richTextManager.getPlainText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Dismiss if no text is entered
        guard !plainText.isEmpty else {
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
                // Update existing entry
                existingEntry.bodyText = plainText
                existingEntry.bodyHTML = htmlString
                existingEntry.date = date
                existingEntry.photos = photoData.isEmpty ? nil : photoData
            }
        } else {
            // Create new entry
            let newEntry = Entry(bodyText: plainText, date: date, bodyHTML: htmlString, photos: photoData.isEmpty ? nil : photoData)
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


