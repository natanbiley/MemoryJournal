import Foundation
import UIKit

final class MediaStorageManager {
    static let shared = MediaStorageManager()

    private let fileManager = FileManager.default

    private init() {
        createMediaDirectoryIfNeeded()
    }

    // MARK: - Directory Structure
    // Documents/Media/{entryUUID}/
    //   ├── thumbnails/
    //   └── compressed/

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var mediaBaseDirectory: URL {
        documentsDirectory.appendingPathComponent("Media", isDirectory: true)
    }

    func mediaDirectory(for entryID: UUID) -> URL {
        mediaBaseDirectory.appendingPathComponent(entryID.uuidString, isDirectory: true)
    }

    private func thumbnailsDirectory(for entryID: UUID) -> URL {
        mediaDirectory(for: entryID).appendingPathComponent("thumbnails", isDirectory: true)
    }

    private func compressedDirectory(for entryID: UUID) -> URL {
        mediaDirectory(for: entryID).appendingPathComponent("compressed", isDirectory: true)
    }

    // MARK: - Directory Creation

    private func createMediaDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: mediaBaseDirectory.path) {
            try? fileManager.createDirectory(at: mediaBaseDirectory, withIntermediateDirectories: true)
        }
    }

    func createEntryDirectories(for entryID: UUID) {
        let thumbnails = thumbnailsDirectory(for: entryID)
        let compressed = compressedDirectory(for: entryID)

        try? fileManager.createDirectory(at: thumbnails, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: compressed, withIntermediateDirectories: true)
    }

    // MARK: - Save Operations

    func saveThumbnail(
        _ imageData: Data,
        entryID: UUID,
        mediaID: UUID,
        mediaType: MediaItem.MediaType
    ) -> String? {
        createEntryDirectories(for: entryID)

        let filename = "\(mediaType.rawValue)_\(mediaID.uuidString)_thumb.jpeg"
        let url = thumbnailsDirectory(for: entryID).appendingPathComponent(filename)

        do {
            try imageData.write(to: url)
            return url.path
        } catch {
            print("Failed to save thumbnail: \(error)")
            return nil
        }
    }

    func saveCompressedPhoto(
        _ imageData: Data,
        entryID: UUID,
        mediaID: UUID
    ) -> String? {
        createEntryDirectories(for: entryID)

        let filename = "photo_\(mediaID.uuidString).jpeg"
        let url = compressedDirectory(for: entryID).appendingPathComponent(filename)

        do {
            try imageData.write(to: url)
            return url.path
        } catch {
            print("Failed to save compressed photo: \(error)")
            return nil
        }
    }

    func saveCompressedVideo(
        from sourceURL: URL,
        entryID: UUID,
        mediaID: UUID
    ) -> String? {
        createEntryDirectories(for: entryID)

        let filename = "video_\(mediaID.uuidString).mp4"
        let destinationURL = compressedDirectory(for: entryID).appendingPathComponent(filename)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Failed to save compressed video: \(error)")
            return nil
        }
    }

    // MARK: - Delete Operations

    func deleteMedia(item: MediaItem) {
        if !item.thumbnailPath.isEmpty {
            try? fileManager.removeItem(atPath: item.thumbnailPath)
        }
        if !item.compressedPath.isEmpty {
            try? fileManager.removeItem(atPath: item.compressedPath)
        }
    }

    func deleteAllMedia(for entryID: UUID) {
        let directory = mediaDirectory(for: entryID)
        try? fileManager.removeItem(at: directory)
    }

    // MARK: - Temporary Files

    func temporaryVideoURL() -> URL {
        let tempDir = fileManager.temporaryDirectory
        let filename = "temp_video_\(UUID().uuidString).mp4"
        return tempDir.appendingPathComponent(filename)
    }

    func cleanupTemporaryFiles() {
        let tempDir = fileManager.temporaryDirectory
        guard let files = try? fileManager.contentsOfDirectory(atPath: tempDir.path) else { return }

        for file in files where file.hasPrefix("temp_video_") {
            let fileURL = tempDir.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Validation

    func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func mediaDirectorySize(for entryID: UUID) -> Int64 {
        let directory = mediaDirectory(for: entryID)
        return directorySize(at: directory)
    }

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
}
