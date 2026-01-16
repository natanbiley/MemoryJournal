import SwiftUI

struct MediaToolbar: View {
    let photoCount: Int
    let videoCount: Int
    let photoLimit: Int
    let videoLimit: Int
    let onAddPhoto: () -> Void
    let onAddVideo: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            photoButton
            videoButton
            Spacer()
            dismissButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var photoButton: some View {
        Button(action: onAddPhoto) {
            HStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.system(size: 16))
                Text("\(photoCount)/\(photoLimit)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(photoCount >= photoLimit ? .secondary : .primary)
        }
        .disabled(photoCount >= photoLimit)
    }

    private var videoButton: some View {
        Button(action: onAddVideo) {
            HStack(spacing: 4) {
                Image(systemName: "video")
                    .font(.system(size: 16))
                Text("\(videoCount)/\(videoLimit)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(videoLimit == 0 || videoCount >= videoLimit ? .secondary : .primary)
        }
        .disabled(videoLimit == 0 || videoCount >= videoLimit)
    }

    private var dismissButton: some View {
        Button(action: onDismissKeyboard) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 18))
                .foregroundStyle(.primary)
        }
    }
}
