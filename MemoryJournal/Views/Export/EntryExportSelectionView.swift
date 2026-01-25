import SwiftUI
import SwiftData

struct EntryExportSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries",
                        systemImage: "doc.text",
                        description: Text("Create some entries first to export them.")
                    )
                } else {
                    List(entries, selection: $selectedEntryIDs) { entry in
                        EntryExportRow(entry: entry, isSelected: selectedEntryIDs.contains(entry.entryID))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(entry.entryID)
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Entries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        exportSelected()
                    }
                    .disabled(selectedEntryIDs.isEmpty || isExporting)
                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(selectedEntryIDs.count == entries.count ? "Deselect All" : "Select All") {
                            toggleSelectAll()
                        }

                        Spacer()

                        Text("\(selectedEntryIDs.count) selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if isExporting {
                    ExportProgressOverlay()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedEntryIDs.contains(id) {
            selectedEntryIDs.remove(id)
        } else {
            selectedEntryIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        if selectedEntryIDs.count == entries.count {
            selectedEntryIDs.removeAll()
        } else {
            selectedEntryIDs = Set(entries.map { $0.entryID })
        }
    }

    private func exportSelected() {
        let entriesToExport = entries.filter { selectedEntryIDs.contains($0.entryID) }

        isExporting = true

        Task {
            do {
                let url = try await ExportImportService.shared.exportEntries(entriesToExport)
                exportedFileURL = url
                isExporting = false
                showShareSheet = true
            } catch {
                isExporting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Entry Export Row

struct EntryExportRow: View {
    let entry: Entry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(entry.bodyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !entry.mediaItems.isEmpty {
                    HStack(spacing: 8) {
                        let photoCount = entry.photos.count
                        let videoCount = entry.videos.count

                        if photoCount > 0 {
                            Label("\(photoCount)", systemImage: "photo")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if videoCount > 0 {
                            Label("\(videoCount)", systemImage: "video")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Export Progress Overlay

struct ExportProgressOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Exporting...")
                    .font(.headline)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EntryExportSelectionView()
}
