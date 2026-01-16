import Foundation
import UIKit
import AVFoundation

final class MediaCompressionService {
    static let shared = MediaCompressionService()

    private init() {}

    // MARK: - Photo Compression

    func compressPhoto(
        _ image: UIImage,
        maxDimension: CGFloat = 2048,
        quality: CGFloat = 0.85
    ) -> Data? {
        let resized = resizeImage(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }

    func generateThumbnail(
        _ image: UIImage,
        size: CGFloat = 300,
        quality: CGFloat = 0.7
    ) -> Data? {
        let resized = resizeImage(image, maxDimension: size)
        return resized.jpegData(compressionQuality: quality)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Video Compression

    func compressVideo(
        at sourceURL: URL,
        to outputURL: URL,
        preset: String = AVAssetExportPresetMediumQuality
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw CompressionError.exportSessionCreationFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            throw exportSession.error ?? CompressionError.unknown
        case .cancelled:
            throw CompressionError.cancelled
        default:
            throw CompressionError.unknown
        }
    }

    // MARK: - Video Thumbnail

    func generateVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 300, height: 300)

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Failed to generate video thumbnail: \(error)")
            return nil
        }
    }

    // MARK: - Video Duration

    func getVideoDuration(from url: URL) -> Double? {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        guard duration.timescale > 0 else { return nil }
        return CMTimeGetSeconds(duration)
    }

    // MARK: - Errors

    enum CompressionError: Error, LocalizedError {
        case exportSessionCreationFailed
        case cancelled
        case unknown

        var errorDescription: String? {
            switch self {
            case .exportSessionCreationFailed:
                return "Failed to create video export session"
            case .cancelled:
                return "Video compression was cancelled"
            case .unknown:
                return "An unknown error occurred during compression"
            }
        }
    }
}
