import SwiftUI

struct VideoThumbnailView: View {
    let mediaItem: MediaItem
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var thumbnailImage: UIImage?

    private let thumbnailSize: CGFloat = 80
    private let cornerRadius: CGFloat = 8
    private let deleteButtonSize: CGFloat = 22

    var body: some View {
        Button(action: onTap) {
            thumbnailContent
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(alignment: .bottomLeading) {
                    if !mediaItem.isProcessing {
                        durationBadge
                    }
                }
                .overlay(alignment: .topTrailing) {
                    deleteButton
                }
                .overlay {
                    if mediaItem.isProcessing {
                        processingOverlay
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(mediaItem.isProcessing)
        .onAppear(perform: loadThumbnail)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let image = thumbnailImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.gray)
                }
        }
    }

    private var durationBadge: some View {
        Group {
            if let duration = mediaItem.formattedDuration {
                Text(duration)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: deleteButtonSize))
                .foregroundStyle(.white, .black.opacity(0.6))
        }
        .offset(x: 4, y: -4)
    }

    private var processingOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.black.opacity(0.5))
            .frame(width: thumbnailSize, height: thumbnailSize)
            .overlay {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
            }
    }

    private func loadThumbnail() {
        guard thumbnailImage == nil else { return }

        Task {
            if let url = mediaItem.thumbnailURL,
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                await MainActor.run {
                    thumbnailImage = image
                }
            }
        }
    }
}
