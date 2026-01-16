import SwiftUI

struct MediaScrollRow: View {
    let mediaItems: [MediaItem]
    let mediaType: MediaItem.MediaType
    let onTap: (MediaItem) -> Void
    let onDelete: (MediaItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(mediaItems, id: \.id) { item in
                    if mediaType == .photo {
                        PhotoThumbnailView(
                            mediaItem: item,
                            onTap: { onTap(item) },
                            onDelete: { onDelete(item) }
                        )
                    } else {
                        VideoThumbnailView(
                            mediaItem: item,
                            onTap: { onTap(item) },
                            onDelete: { onDelete(item) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 88)
    }
}
