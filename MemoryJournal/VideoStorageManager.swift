import Foundation
import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

/// Manages video file storage in the app's Documents directory
/// Videos are stored with unique filenames and only the filenames are persisted in SwiftData
actor VideoStorageManager {
    static let shared = VideoStorageManager()
    
    private let fileManager = FileManager.default
    private let videosDirectoryName = "EntryVideos"
    
    private init() {
        // Ensure videos directory exists
        Task {
            await createVideosDirectoryIfNeeded()
        }
    }
    
    /// Returns the URL to the videos directory
    private var videosDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(videosDirectoryName)
    }
    
    /// Creates the videos directory if it doesn't exist
    private func createVideosDirectoryIfNeeded() {
        let url = videosDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the full URL for a video filename
    func videoURL(for filename: String) -> URL {
        return videosDirectoryURL.appendingPathComponent(filename)
    }
    
    /// Saves video data from a PhotosPickerItem to the Documents directory
    /// Returns the filename (not full path) on success
    func saveVideo(from item: PhotosPickerItem) async -> String? {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            print("❌ Failed to load video data from picker item")
            return nil
        }
        
        return await saveVideoData(data)
    }
    
    /// Saves raw video data to the Documents directory
    /// Returns the filename (not full path) on success
    func saveVideoData(_ data: Data) async -> String? {
        await createVideosDirectoryIfNeeded()
        
        let filename = UUID().uuidString + ".mp4"
        let fileURL = videosDirectoryURL.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved video: \(filename) (\(data.count / 1_000_000) MB)")
            return filename
        } catch {
            print("❌ Error saving video: \(error)")
            return nil
        }
    }
    
    /// Copies a video from a temporary URL to permanent storage
    /// Returns the new filename on success
    func moveVideoToPermanentStorage(from tempURL: URL) async -> String? {
        await createVideosDirectoryIfNeeded()
        
        let filename = UUID().uuidString + ".mp4"
        let destinationURL = videosDirectoryURL.appendingPathComponent(filename)
        
        do {
            // Use copy instead of move in case the temp file is still needed
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            print("✅ Copied video to permanent storage: \(filename)")
            return filename
        } catch {
            print("❌ Error copying video to permanent storage: \(error)")
            return nil
        }
    }
    
    /// Deletes a video file by filename
    func deleteVideo(filename: String) {
        let fileURL = videosDirectoryURL.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
        print("🗑️ Deleted video: \(filename)")
    }
    
    /// Deletes multiple video files
    func deleteVideos(filenames: [String]) {
        for filename in filenames {
            deleteVideo(filename: filename)
        }
    }
    
    /// Checks if a video file exists
    func videoExists(filename: String) -> Bool {
        let fileURL = videosDirectoryURL.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Generates a thumbnail from a video file
    func generateThumbnail(for filename: String) async -> UIImage? {
        let fileURL = videosDirectoryURL.appendingPathComponent(filename)
        return await generateThumbnail(from: fileURL)
    }
    
    /// Generates a thumbnail from a video URL
    func generateThumbnail(from videoURL: URL) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 200, height: 200)
            
            // Try to get thumbnail at 1 second
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                // Try at the beginning if 1 second fails
                let startTime = CMTime(seconds: 0.1, preferredTimescale: 600)
                if let cgImage = try? imageGenerator.copyCGImage(at: startTime, actualTime: nil) {
                    return UIImage(cgImage: cgImage)
                }
                return nil
            }
        }.value
    }
    
    /// Returns the file size in bytes for a video
    func videoFileSize(filename: String) -> Int64? {
        let fileURL = videosDirectoryURL.appendingPathComponent(filename)
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
    
    /// Cleans up orphaned video files that are no longer referenced by any entry
    /// Call this periodically to free up storage
    func cleanupOrphanedVideos(referencedFilenames: Set<String>) {
        guard let files = try? fileManager.contentsOfDirectory(atPath: videosDirectoryURL.path) else {
            return
        }
        
        for file in files where file.hasSuffix(".mp4") {
            if !referencedFilenames.contains(file) {
                deleteVideo(filename: file)
                print("🧹 Cleaned up orphaned video: \(file)")
            }
        }
    }
}
