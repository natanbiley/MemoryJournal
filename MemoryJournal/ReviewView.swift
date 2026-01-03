import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: \Entry.date, order: .reverse) private var allEntries: [Entry]
    @Environment(\.modelContext) private var context
    @State private var store = EntryStore()
    private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var selectedYear: Int
    @State private var isOnThisDayExpanded = true
    @State private var isMonthReviewExpanded = true
    @State private var isYearReviewExpanded = true
    
    init() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        _selectedYear = State(initialValue: currentYear - 1)
    }
    
    private var onThisDayEntries: [Entry] {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        return allEntries.filter { entry in
            let entryDay = calendar.component(.day, from: entry.date)
            let entryMonth = calendar.component(.month, from: entry.date)
            let entryYear = calendar.component(.year, from: entry.date)
            
            // Same day and month, but different year
            return entryDay == currentDay && 
                   entryMonth == currentMonth && 
                   entryYear != currentYear
        }
    }
    
    private var lastMonthEntries: [Entry] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the first day of current month
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: today)?.start else {
            return []
        }
        
        // Get the previous month's date range
        guard let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart),
              let previousMonthInterval = calendar.dateInterval(of: .month, for: previousMonthStart) else {
            return []
        }
        
        // Filter entries from previous month
        let filtered = allEntries.filter { entry in
            previousMonthInterval.contains(entry.date)
        }
        
        // Sort: favorites first, then by content richness
        return filtered.sorted { entry1, entry2 in
            // Favorites always come first
            if entry1.isFavorite != entry2.isFavorite {
                return entry1.isFavorite
            }
            
            // Calculate content score (text length + photo count)
            let score1 = contentScore(for: entry1)
            let score2 = contentScore(for: entry2)
            
            return score1 > score2
        }
    }
    
    private var lastYearEntries: [Entry] {
        let calendar = Calendar.current
        
        // Create date components for the selected year
        var components = DateComponents()
        components.year = selectedYear
        components.month = 1
        components.day = 1
        
        guard let yearStart = calendar.date(from: components),
              let yearInterval = calendar.dateInterval(of: .year, for: yearStart) else {
            return []
        }
        
        // Filter entries from selected year
        let filtered = allEntries.filter { entry in
            yearInterval.contains(entry.date)
        }
        
        // Sort: favorites first, then by content richness, and take top 10
        let sorted = filtered.sorted { entry1, entry2 in
            // Favorites always come first
            if entry1.isFavorite != entry2.isFavorite {
                return entry1.isFavorite
            }
            
            // Calculate content score (text length + photo count)
            let score1 = contentScore(for: entry1)
            let score2 = contentScore(for: entry2)
            
            return score1 > score2
        }
        
        return Array(sorted.prefix(10))
    }
    
    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(allEntries.map { calendar.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }
    
    private func contentScore(for entry: Entry) -> Int {
        let textLength = stripHTML(entry.bodyText).count
        let photoCount = (entry.photos?.count ?? 0) * 100 // Weight photos heavily
        return textLength + photoCount
    }
    
    private var previousMonthName: String {
        let calendar = Calendar.current
        let today = Date()
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: today)?.start,
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return "Last Month"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: previousMonthStart)
    }
    
    private var currentStreak: Int {
        guard !allEntries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = calendar.startOfDay(for: today)
        
        // Get all entry dates as start of day
        let entryDates = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
        
        // Check if there's an entry today or yesterday to start streak
        if !entryDates.contains(currentDate) {
            // If no entry today, check yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate),
                  entryDates.contains(yesterday) else {
                return 0
            }
            currentDate = yesterday
        }
        
        // Count consecutive days backwards
        while entryDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
    
    private var longestStreak: Int {
        guard !allEntries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        
        // Get unique entry dates sorted
        let entryDates = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
            .sorted()
        
        guard !entryDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreakCount = 1
        
        for i in 1..<entryDates.count {
            let previousDate = entryDates[i - 1]
            let currentDate = entryDates[i]
            
            // Check if dates are consecutive
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(nextDay, inSameDayAs: currentDate) {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        
        return maxStreak
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Streak Tracker Section
                    HStack(spacing: 16) {
                        // Current Streak
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange.gradient)
                                Text("\(currentStreak)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(currentStreak == 1 ? "day" : "days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Current Streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.orange.opacity(0.1))
                        )
                        
                        // Longest Streak
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundStyle(.yellow.gradient)
                                Text("\(longestStreak)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(currentStreak == 1 ? "day" : "days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Longest Streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.yellow.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // On This Day Section
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation {
                                isOnThisDayExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text("On This Day")
                                    .font(.title2)
                                    .bold()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isOnThisDayExpanded ? 90 : 0))
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if isOnThisDayExpanded {
                            Text("Memories from previous years")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            if !onThisDayEntries.isEmpty {
                                ForEach(onThisDayEntries) { entry in
                                    OnThisDayCard(entry: entry, store: store, context: context)
                                        .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("No memories from this day")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Check back as you add more entries throughout the years")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Last Month Review Section
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            if subscriptionManager.canAccessReviews() {
                                withAnimation {
                                    isMonthReviewExpanded.toggle()
                                }
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                Text("\(previousMonthName) Review")
                                    .font(.title2)
                                    .bold()
                                
                                if !subscriptionManager.canAccessReviews() {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(.orange.opacity(0.2))
                                        )
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isMonthReviewExpanded ? 90 : 0))
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if isMonthReviewExpanded && subscriptionManager.canAccessReviews() {
                            Text("Your highlights from last month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            if !lastMonthEntries.isEmpty {
                                ForEach(lastMonthEntries) { entry in
                                    MonthReviewCard(entry: entry, store: store, context: context)
                                        .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.checkmark")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("No entries from \(previousMonthName)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Start journaling to build your monthly reviews")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        } else if !subscriptionManager.canAccessReviews() {
                            // Premium teaser
                            VStack(spacing: 16) {
                                Image(systemName: "rosette")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.orange.gradient)
                                
                                Text("Premium Feature")
                                    .font(.title3)
                                    .bold()
                                
                                Text("Upgrade to Premium to unlock monthly review summaries of your best moments")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button {
                                    showPaywall = true
                                } label: {
                                    Text("Unlock Month Reviews")
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.orange.gradient)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // Last Year Review Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                if subscriptionManager.canAccessReviews() {
                                    withAnimation {
                                        isYearReviewExpanded.toggle()
                                    }
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    Text("Year Highlights")
                                        .font(.title2)
                                        .bold()
                                    
                                    if !subscriptionManager.canAccessReviews() {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(.orange.opacity(0.2))
                                            )
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            if !availableYears.isEmpty && subscriptionManager.canAccessReviews() {
                                Menu {
                                    ForEach(availableYears, id: \.self) { year in
                                        Button {
                                            selectedYear = year
                                        } label: {
                                            HStack {
                                                Text(verbatim: "\(year)")
                                                if year == selectedYear {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(verbatim: "\(selectedYear)")
                                            .font(.headline)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.orange.opacity(0.15))
                                    )
                                }
                            }
                            
                            Button {
                                if subscriptionManager.canAccessReviews() {
                                    withAnimation {
                                        isYearReviewExpanded.toggle()
                                    }
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isYearReviewExpanded ? 90 : 0))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        
                        if isYearReviewExpanded && subscriptionManager.canAccessReviews() {
                            Text(verbatim: "Your top moments from \(selectedYear)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            if !lastYearEntries.isEmpty {
                                ForEach(lastYearEntries) { entry in
                                    YearReviewCard(entry: entry, store: store, context: context)
                                        .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.secondary)
                                    
                                    Text(verbatim: "No entries from \(selectedYear)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Keep journaling to create your year-end highlights")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        } else if !subscriptionManager.canAccessReviews() {
                            // Premium teaser
                            VStack(spacing: 16) {
                                Image(systemName: "rosette")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.orange.gradient)
                                
                                Text("Premium Feature")
                                    .font(.title3)
                                    .bold()
                                
                                Text("Upgrade to Premium to unlock yearly highlights and relive your best moments")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button {
                                    showPaywall = true
                                } label: {
                                    Text("Unlock Year Highlights")
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.orange.gradient)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Review")
            .sheet(isPresented: $store.isShowingEditor) {
                EntryEditor()
                    .environment(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func stripHTML(_ html: String) -> String {
        // Simple HTML stripping - remove tags but keep content
        let pattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: html.utf16.count)
            let strippedString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
            return strippedString
        }
        return html
    }
}

struct OnThisDayCard: View {
    let entry: Entry
    let store: EntryStore
    let context: ModelContext
    
    private var yearsSince: Int {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let entryYear = calendar.component(.year, from: entry.date)
        return currentYear - entryYear
    }
    
    private var displayText: String {
        // Always strip HTML from bodyText for consistent display
        let text = entry.bodyText
        return stripHTML(text)
    }
    
    var body: some View {
        Button {
            store.showEditor(for: entry.persistentModelID, context: context)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(yearsSince) \(yearsSince == 1 ? "year" : "years") ago")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.blue.gradient)
                        )
                    
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(displayText)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                
                if let photos = entry.photos, !photos.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text("\(photos.count) \(photos.count == 1 ? "photo" : "photos")")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func stripHTML(_ html: String) -> String {
        // Simple HTML stripping - remove tags but keep content
        let pattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: html.utf16.count)
            let strippedString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
            return strippedString
        }
        return html
    }
}

struct MonthReviewCard: View {
    let entry: Entry
    let store: EntryStore
    let context: ModelContext
    
    private var displayText: String {
        let text = entry.bodyText
        return stripHTML(text)
    }
    
    var body: some View {
        Button {
            store.showEditor(for: entry.persistentModelID, context: context)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Text(displayText)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundStyle(.primary)
                
                if let photos = entry.photos, !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photos.prefix(3), id: \.self) { photoData in
                                if let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            if photos.count > 3 {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.secondary.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Text("+\(photos.count - 3)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func stripHTML(_ html: String) -> String {
        let pattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: html.utf16.count)
            let strippedString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
            return strippedString
        }
        return html
    }
}

struct YearReviewCard: View {
    let entry: Entry
    let store: EntryStore
    let context: ModelContext
    
    private var displayText: String {
        let text = entry.bodyText
        return stripHTML(text)
    }
    
    var body: some View {
        Button {
            store.showEditor(for: entry.persistentModelID, context: context)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Text(displayText)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundStyle(.primary)
                
                if let photos = entry.photos, !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photos.prefix(3), id: \.self) { photoData in
                                if let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            if photos.count > 3 {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.secondary.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Text("+\(photos.count - 3)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func stripHTML(_ html: String) -> String {
        let pattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: html.utf16.count)
            let strippedString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
            return strippedString
        }
        return html
    }
}

#Preview {
    ReviewView()
        .modelContainer(SampleData.shared.modelContainer)
}
