import Foundation
import SwiftData
import UIKit

// MARK: - Export Data Models

struct ExportedJournal: Codable {
    let version: String
    let exportDate: Date
    let entries: [ExportedEntry]

    static let currentVersion = "1.0"
}

struct ExportedEntry: Codable {
    let entryID: UUID
    let bodyText: String
    let date: Date
    let isFavorite: Bool
    let mediaItems: [ExportedMediaItem]
}

struct ExportedMediaItem: Codable {
    let id: UUID
    let mediaType: String
    let createdAt: Date
    let duration: Double?
    let sortOrder: Int
    let thumbnailBase64: String?
    let compressedBase64: String?
}

// MARK: - Export/Import Service

class ExportImportService {
    static let shared = ExportImportService()

    private init() {}

    // MARK: - Export

    func exportEntries(_ entries: [Entry]) async throws -> URL {
        var exportedEntries: [ExportedEntry] = []

        for entry in entries {
            let exportedEntry = try await exportEntry(entry)
            exportedEntries.append(exportedEntry)
        }

        let exportedJournal = ExportedJournal(
            version: ExportedJournal.currentVersion,
            exportDate: Date(),
            entries: exportedEntries
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportedJournal)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "DayScribe_Export_\(timestamp).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)

        return tempURL
    }

    private func exportEntry(_ entry: Entry) async throws -> ExportedEntry {
        var exportedMediaItems: [ExportedMediaItem] = []

        for mediaItem in entry.mediaItems {
            let exportedMedia = await exportMediaItem(mediaItem)
            exportedMediaItems.append(exportedMedia)
        }

        return ExportedEntry(
            entryID: entry.entryID,
            bodyText: entry.bodyText,
            date: entry.date,
            isFavorite: entry.isFavorite,
            mediaItems: exportedMediaItems
        )
    }

    private func exportMediaItem(_ mediaItem: MediaItem) async -> ExportedMediaItem {
        var thumbnailBase64: String?
        var compressedBase64: String?

        if let thumbnailURL = mediaItem.thumbnailURL,
           let thumbnailData = try? Data(contentsOf: thumbnailURL) {
            thumbnailBase64 = thumbnailData.base64EncodedString()
        }

        if let compressedURL = mediaItem.compressedURL,
           let compressedData = try? Data(contentsOf: compressedURL) {
            compressedBase64 = compressedData.base64EncodedString()
        }

        return ExportedMediaItem(
            id: mediaItem.id,
            mediaType: mediaItem.mediaTypeRaw,
            createdAt: mediaItem.createdAt,
            duration: mediaItem.duration,
            sortOrder: mediaItem.sortOrder,
            thumbnailBase64: thumbnailBase64,
            compressedBase64: compressedBase64
        )
    }

    // MARK: - Import

    func importEntries(from url: URL, context: ModelContext) async throws -> ImportResult {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportedJournal = try decoder.decode(ExportedJournal.self, from: data)

        let existingEntryIDs = try fetchExistingEntryIDs(context: context)

        var importedCount = 0
        var skippedCount = 0

        for exportedEntry in exportedJournal.entries {
            if existingEntryIDs.contains(exportedEntry.entryID) {
                skippedCount += 1
            } else {
                try await importEntry(exportedEntry, context: context)
                importedCount += 1
            }
        }

        try context.save()

        return ImportResult(imported: importedCount, skipped: skippedCount)
    }

    private func fetchExistingEntryIDs(context: ModelContext) throws -> Set<UUID> {
        let descriptor = FetchDescriptor<Entry>()
        let entries = try context.fetch(descriptor)
        return Set(entries.map { $0.entryID })
    }

    private func importEntry(_ exportedEntry: ExportedEntry, context: ModelContext) async throws {
        let entry = Entry(
            bodyText: exportedEntry.bodyText,
            date: exportedEntry.date,
            isFavorite: exportedEntry.isFavorite
        )
        entry.entryID = exportedEntry.entryID

        context.insert(entry)

        for exportedMedia in exportedEntry.mediaItems {
            try await importMediaItem(exportedMedia, for: entry)
        }
    }

    private func importMediaItem(_ exportedMedia: ExportedMediaItem, for entry: Entry) async throws {
        guard let thumbnailBase64 = exportedMedia.thumbnailBase64,
              let compressedBase64 = exportedMedia.compressedBase64,
              let thumbnailData = Data(base64Encoded: thumbnailBase64),
              let compressedData = Data(base64Encoded: compressedBase64) else {
            return
        }

        let mediaType = MediaItem.MediaType(rawValue: exportedMedia.mediaType) ?? .photo
        let fileExtension = mediaType == .photo ? "jpeg" : "mp4"

        let mediaDirectory = MediaStorageManager.shared.mediaDirectory(for: entry.entryID)
        let thumbnailsDir = mediaDirectory.appendingPathComponent("thumbnails")
        let compressedDir = mediaDirectory.appendingPathComponent("compressed")

        try FileManager.default.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: compressedDir, withIntermediateDirectories: true)

        let prefix = mediaType == .photo ? "photo" : "video"
        let thumbnailPath = thumbnailsDir.appendingPathComponent("\(prefix)_\(exportedMedia.id.uuidString).jpeg")
        let compressedPath = compressedDir.appendingPathComponent("\(prefix)_\(exportedMedia.id.uuidString).\(fileExtension)")

        try thumbnailData.write(to: thumbnailPath)
        try compressedData.write(to: compressedPath)

        let mediaItem = MediaItem(
            id: exportedMedia.id,
            mediaType: mediaType,
            thumbnailPath: thumbnailPath.path,
            compressedPath: compressedPath.path,
            createdAt: exportedMedia.createdAt,
            duration: exportedMedia.duration,
            sortOrder: exportedMedia.sortOrder,
            isProcessing: false
        )

        entry.mediaItems.append(mediaItem)
    }
}

// MARK: - Import Result

struct ImportResult {
    let imported: Int
    let skipped: Int

    var message: String {
        if skipped > 0 {
            return "Imported \(imported) entries. Skipped \(skipped) duplicates."
        } else {
            return "Successfully imported \(imported) entries."
        }
    }
}
