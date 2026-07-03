import SwiftUI

struct RidgitsCachedProfileImage<Placeholder: View>: View {
    let remoteURL: String?
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: remoteURL) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        guard let remoteURL, !remoteURL.isEmpty else {
            loadedImage = nil
            return
        }

        if let cached = RidgitsProfileCache.shared.cachedUIImage(for: remoteURL) {
            loadedImage = cached
            return
        }

        await RidgitsProfileCache.shared.prefetchImage(remoteURL: remoteURL)
        loadedImage = RidgitsProfileCache.shared.cachedUIImage(for: remoteURL)
    }
}

extension RidgitsCachedProfileImage where Placeholder == Color {
    init(remoteURL: String?) {
        self.remoteURL = remoteURL
        self.placeholder = { Color.clear }
    }
}
