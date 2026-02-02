import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    private var subscriptionManager = SubscriptionManager.shared
    @State private var reminderManager = ReminderManager.shared
    @State private var showPaywall = false
    @State private var showExportSelection = false
    @State private var showImportPicker = false
    @State private var isExportingAll = false
    @State private var isImporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showImportResult = false
    @State private var importResultMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    if subscriptionManager.isPremium {
                        HStack {
                            Image(systemName: "rosette")
                                .foregroundStyle(.orange.gradient)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Member")
                                    .font(.headline)
                                
                                if let product = subscriptionManager.purchasedSubscriptions.first {
                                    Text(product.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Manage Subscription")
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption)
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "rosette")
                                            .foregroundStyle(.orange)
                                        Text("Upgrade to Premium")
                                            .font(.headline)
                                    }
                                    
                                    Text("Unlock videos, unlimited photos, and reviews")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Premium Features Section
                if !subscriptionManager.isPremium {
                    Section {
                        FeatureRow(
                            icon: "video.fill",
                            color: .blue,
                            title: "Video Memories",
                            description: "Add videos to entries"
                        )
                        
                        FeatureRow(
                            icon: "photo.stack.fill",
                            color: .green,
                            title: "Unlimited Photos",
                            description: "No limit on photos per entry"
                        )
                        
                        FeatureRow(
                            icon: "calendar.badge.checkmark",
                            color: .purple,
                            title: "Month Reviews",
                            description: "Monthly highlight summaries"
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            color: .orange,
                            title: "Year Highlights",
                            description: "Annual memory collections"
                        )

                        FeatureRow(
                            icon: "square.and.arrow.up",
                            color: .teal,
                            title: "Export Entries",
                            description: "Backup and share your journal"
                        )
                    }
                }
                    
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Restore Purchases")
                            Spacer()
                        }
                    }
                    .disabled(subscriptionManager.isLoading)
                } header: {
                    Text("Subscription")
                }

                // Reminders Section
                Section {
                    Toggle("Daily Reminder", isOn: Binding(
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
                                    } else {
                                        // Permission denied - open settings
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            await UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            } else {
                                reminderManager.isEnabled = false
                            }
                        }
                    ))

                    if reminderManager.isEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: { reminderManager.reminderTime },
                                set: { reminderManager.reminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Get a daily notification to remind you to journal.")
                }

                // Import/Export Section
                Section {
                    Button {
                        if subscriptionManager.isPremium {
                            exportAllEntries()
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Label("Export All Entries", systemImage: "square.and.arrow.up")
                            Spacer()
                            if isExportingAll {
                                ProgressView()
                            } else if !subscriptionManager.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(entries.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(entries.isEmpty || isExportingAll)

                    Button {
                        if subscriptionManager.isPremium {
                            showExportSelection = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Label("Select Entries to Export", systemImage: "checklist")
                            Spacer()
                            if !subscriptionManager.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(entries.isEmpty)

                    Button {
                        showImportPicker = true
                    } label: {
                        HStack {
                            Label("Import Entries", systemImage: "square.and.arrow.down")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Import & Export")
                } footer: {
                    Text(subscriptionManager.isPremium
                         ? "Export creates a JSON file with all entry data and media. Import will skip duplicate entries."
                         : "Export requires Premium. Import is free to restore your data on a new device.")
                }

                // App Information
                Section {
                    Link(destination: URL(string: "https://natanbiley.github.io/MemoryJournal/")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        HStack {
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showExportSelection) {
                EntryExportSelectionView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Complete", isPresented: $showImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importResultMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Export/Import Functions

    private func exportAllEntries() {
        isExportingAll = true

        Task {
            do {
                let url = try await ExportImportService.shared.exportEntries(entries)
                exportedFileURL = url
                isExportingAll = false
                showShareSheet = true
            } catch {
                isExportingAll = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file."
                showError = true
                return
            }

            isImporting = true

            Task {
                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                do {
                    let importResult = try await ExportImportService.shared.importEntries(from: url, context: modelContext)
                    isImporting = false
                    importResultMessage = importResult.message
                    showImportResult = true
                } catch {
                    isImporting = false
                    errorMessage = "Import failed: \(error.localizedDescription)"
                    showError = true
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
