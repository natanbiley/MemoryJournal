import Foundation
import SwiftUI
import PhotosUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("temp_video_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

@Observable
class MediaViewModel {
    var photos: [MediaItem] = []
    var videos: [MediaItem] = []
    var isProcessingVideo = false
    var showPaywall = false
    var showGallery = false
    var selectedGalleryIndex = 0
    var galleryMediaType: MediaItem.MediaType = .photo

    private let storageManager = MediaStorageManager.shared
    private let compressionService = MediaCompressionService.shared
    private let subscriptionManager = SubscriptionManager.shared

    // MARK: - Limits

    var photoLimit: Int {
        subscriptionManager.isPremium ? 10 : 2
    }

    var videoLimit: Int {
        subscriptionManager.isPremium ? 5 : 0
    }

    var canAddPhoto: Bool {
        photos.count < photoLimit
    }

    var canAddVideo: Bool {
        videos.count < videoLimit
    }

    // MARK: - Load Media

    func loadMedia(from entry: Entry?) {
        guard let entry = entry else {
            photos = []
            videos = []
            return
        }

        photos = entry.photos
        videos = entry.videos
    }

    // MARK: - Premium Gating

    func checkPhotoLimitAndShowPaywall() -> Bool {
        if canAddPhoto {
            return true
        }
        showPaywall = true
        return false
    }

    func checkVideoLimitAndShowPaywall() -> Bool {
        if canAddVideo {
            return true
        }
        showPaywall = true
        return false
    }

    // MARK: - Add Photo

    func addPhoto(
        from result: PHPickerResult,
        entry: Entry,
        context: ModelContext
    ) {
        guard canAddPhoto else {
            showPaywall = true
            return
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self,
                  let image = object as? UIImage else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            Task { @MainActor in
                self.processAndSavePhoto(image: image, entry: entry, context: context)
            }
        }
    }

    @MainActor
    func processAndSavePhotoDirectly(
        image: UIImage,
        entry: Entry,
        context: ModelContext
    ) {
        processAndSavePhoto(image: image, entry: entry, context: context)
    }

    @MainActor
    private func processAndSavePhoto(
        image: UIImage,
        entry: Entry,
        context: ModelContext
    ) {
        let mediaID = UUID()
        let entryID = entry.entryID

        // Generate thumbnail
        guard let thumbnailData = compressionService.generateThumbnail(image),
              let thumbnailPath = storageManager.saveThumbnail(
                thumbnailData,
                entryID: entryID,
                mediaID: mediaID,
                mediaType: .photo
              ) else {
            print("Failed to save thumbnail")
            return
        }

        // Compress photo
        guard let compressedData = compressionService.compressPhoto(image),
              let compressedPath = storageManager.saveCompressedPhoto(
                compressedData,
                entryID: entryID,
                mediaID: mediaID
              ) else {
            print("Failed to save compressed photo")
            return
        }

        // Create MediaItem
        let mediaItem = MediaItem(
            id: mediaID,
            mediaType: .photo,
            thumbnailPath: thumbnailPath,
            compressedPath: compressedPath,
            sortOrder: photos.count
        )

        // Add to entry
        entry.mediaItems.append(mediaItem)
        photos.append(mediaItem)

        // Save context
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // MARK: - Add Video

    func addVideo(
        from result: PHPickerResult,
        entry: Entry,
        context: ModelContext
    ) {
        guard canAddVideo else {
            showPaywall = true
            return
        }

        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self = self,
                  let sourceURL = url else {
                print("Failed to load video: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Copy to temporary location (original URL is deleted after this callback)
            let tempURL = self.storageManager.temporaryVideoURL()
            do {
                try FileManager.default.copyItem(at: sourceURL, to: tempURL)
            } catch {
                print("Failed to copy video: \(error)")
                return
            }

            Task { @MainActor in
                await self.processAndSaveVideo(tempURL: tempURL, entry: entry, context: context)
            }
        }
    }

    @MainActor
    func processAndSaveVideoDirectly(
        tempURL: URL,
        entry: Entry,
        context: ModelContext
    ) async {
        await processAndSaveVideo(tempURL: tempURL, entry: entry, context: context)
    }

    @MainActor
    private func processAndSaveVideo(
        tempURL: URL,
        entry: Entry,
        context: ModelContext
    ) async {
        let mediaID = UUID()
        let entryID = entry.entryID

        // Generate thumbnail from first frame
        guard let thumbnailImage = compressionService.generateVideoThumbnail(from: tempURL),
              let thumbnailData = compressionService.generateThumbnail(thumbnailImage),
              let thumbnailPath = storageManager.saveThumbnail(
                thumbnailData,
                entryID: entryID,
                mediaID: mediaID,
                mediaType: .video
              ) else {
            print("Failed to save video thumbnail")
            try? FileManager.default.removeItem(at: tempURL)
            return
        }

        // Get duration
        let duration = compressionService.getVideoDuration(from: tempURL)

        // Create MediaItem with isProcessing = true
        let mediaItem = MediaItem(
            id: mediaID,
            mediaType: .video,
            thumbnailPath: thumbnailPath,
            compressedPath: "",
            duration: duration,
            sortOrder: videos.count,
            isProcessing: true
        )

        // Add to entry immediately (shows in UI with spinner)
        entry.mediaItems.append(mediaItem)
        videos.append(mediaItem)
        isProcessingVideo = true

        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }

        // Compress video in background
        let outputURL = storageManager.temporaryVideoURL()

        do {
            _ = try await compressionService.compressVideo(at: tempURL, to: outputURL)

            // Move to permanent location
            if let compressedPath = storageManager.saveCompressedVideo(
                from: outputURL,
                entryID: entryID,
                mediaID: mediaID
            ) {
                mediaItem.compressedPath = compressedPath
                mediaItem.isProcessing = false

                try context.save()
            }
        } catch {
            print("Video compression failed: \(error)")
            // Remove failed item
            entry.mediaItems.removeAll { $0.id == mediaID }
            videos.removeAll { $0.id == mediaID }
            try? context.save()
        }

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
        isProcessingVideo = false
    }

    // MARK: - Delete Media

    @MainActor
    func deleteMedia(
        item: MediaItem,
        entry: Entry,
        context: ModelContext
    ) {
        // Delete files
        storageManager.deleteMedia(item: item)

        // Remove from entry
        entry.mediaItems.removeAll { $0.id == item.id }

        // Remove from local arrays
        if item.mediaType == .photo {
            photos.removeAll { $0.id == item.id }
        } else {
            videos.removeAll { $0.id == item.id }
        }

        // Delete from context
        context.delete(item)

        // Save
        do {
            try context.save()
        } catch {
            print("Failed to delete media: \(error)")
        }
    }

    // MARK: - Gallery

    func openGallery(for item: MediaItem) {
        galleryMediaType = item.mediaType

        let items = item.mediaType == .photo ? photos : videos
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            selectedGalleryIndex = index
            showGallery = true
        }
    }

    var galleryItems: [MediaItem] {
        galleryMediaType == .photo ? photos : videos
    }
}
