import SwiftUI
import UIKit

/// Avatar loader for social surfaces: null stays placeholder; relative/same-host API paths use Bearer.
struct SocialAvatarView: View {
    let urlString: String?
    var size: CGFloat = 44
    var fallbackSystemImage: String = "person.crop.circle.fill"

    @EnvironmentObject private var container: AppContainer
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: urlString) {
            await reload()
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(DSColor.cardBackground)
            Image(systemName: fallbackSystemImage)
                .font(.system(size: size * 0.56))
                .foregroundStyle(DSColor.primary)
        }
    }

    private func reload() async {
        image = nil
        guard RemoteMapperSupport.sanitizedText(urlString) != nil else {
            return
        }
        let loaded = await container.authenticatedImageLoader.image(for: urlString)
        guard !Task.isCancelled else { return }
        image = loaded
    }
}
