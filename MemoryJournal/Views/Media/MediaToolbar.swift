import SwiftUI

struct MediaToolbar: View {
    let onAddPhoto: () -> Void
    let onAddVideo: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        HStack(spacing: 20) {
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
            Image(systemName: "photo")
                .font(.system(size: 18))
                .foregroundStyle(.primary)
        }
    }

    private var videoButton: some View {
        Button(action: onAddVideo) {
            Image(systemName: "video")
                .font(.system(size: 18))
                .foregroundStyle(.primary)
        }
    }

    private var dismissButton: some View {
        Button(action: onDismissKeyboard) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 18))
                .foregroundStyle(.primary)
        }
    }
}
