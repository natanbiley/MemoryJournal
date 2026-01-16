import Foundation
import SwiftData

@Model
class MediaItem {
    var id: UUID
    var mediaTypeRaw: String
    var thumbnailPath: String
    var compressedPath: String
    var createdAt: Date
    var duration: Double?
    var sortOrder: Int
    var isProcessing: Bool

    @Relationship(inverse: \Entry.mediaItems)
    var entry: Entry?

    var mediaType: MediaType {
        get { MediaType(rawValue: mediaTypeRaw) ?? .photo }
        set { mediaTypeRaw = newValue.rawValue }
    }

    enum MediaType: String, Codable {
        case photo
        case video
    }

    init(
        id: UUID = UUID(),
        mediaType: MediaType,
        thumbnailPath: String,
        compressedPath: String,
        createdAt: Date = Date(),
        duration: Double? = nil,
        sortOrder: Int = 0,
        isProcessing: Bool = false
    ) {
        self.id = id
        self.mediaTypeRaw = mediaType.rawValue
        self.thumbnailPath = thumbnailPath
        self.compressedPath = compressedPath
        self.createdAt = createdAt
        self.duration = duration
        self.sortOrder = sortOrder
        self.isProcessing = isProcessing
    }

    // MARK: - Computed URLs

    var thumbnailURL: URL? {
        guard !thumbnailPath.isEmpty else { return nil }
        return URL(fileURLWithPath: thumbnailPath)
    }

    var compressedURL: URL? {
        guard !compressedPath.isEmpty else { return nil }
        return URL(fileURLWithPath: compressedPath)
    }

    // MARK: - Formatted Duration

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
