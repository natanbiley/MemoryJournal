import SwiftUI

struct PhotoThumbnailView: View {
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
                .overlay(alignment: .topTrailing) {
                    deleteButton
                }
        }
        .buttonStyle(.plain)
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
                    ProgressView()
                        .scaleEffect(0.7)
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
