import SwiftUI
import AVKit

struct MediaGalleryView: View {
    let mediaItems: [MediaItem]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                    MediaGalleryItemView(mediaItem: item, isVisible: index == selectedIndex)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            closeButton
        }
        .onAppear {
            configureAudioSession()
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white, .black.opacity(0.5))
        }
        .padding()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}

struct MediaGalleryItemView: View {
    let mediaItem: MediaItem
    let isVisible: Bool

    @State private var image: UIImage?
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if mediaItem.mediaType == .photo {
                photoView
            } else {
                videoView
            }
        }
        .onAppear(perform: loadMedia)
        .onDisappear(perform: cleanupVideo)
        .onChange(of: isVisible) { _, newValue in
            if newValue && mediaItem.mediaType == .video {
                player?.seek(to: .zero)
                player?.play()
            } else {
                player?.pause()
            }
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
                .tint(.white)
        }
    }

    @ViewBuilder
    private var videoView: some View {
        if let player = player {
            VideoPlayer(player: player)
                .aspectRatio(contentMode: .fit)
                .onAppear {
                    if isVisible {
                        player.play()
                    }
                }
        } else {
            ProgressView()
                .tint(.white)
        }
    }

    private func loadMedia() {
        if mediaItem.mediaType == .photo {
            loadPhoto()
        } else {
            loadVideo()
        }
    }

    private func loadPhoto() {
        guard image == nil else { return }

        Task {
            if let url = mediaItem.compressedURL,
               let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                await MainActor.run {
                    image = loadedImage
                }
            }
        }
    }

    private func loadVideo() {
        guard player == nil, !mediaItem.isProcessing else { return }

        if let url = mediaItem.compressedURL {
            let newPlayer = AVPlayer(url: url)
            newPlayer.actionAtItemEnd = .none
            player = newPlayer
        }
    }

    private func cleanupVideo() {
        player?.pause()
        player = nil
    }
}
