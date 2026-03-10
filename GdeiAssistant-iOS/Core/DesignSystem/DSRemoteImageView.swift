import SwiftUI

struct DSRemoteImageView: View {
    let urlString: String?
    var cornerRadius: CGFloat = 16
    var fallbackSystemImage: String = "photo"

    var body: some View {
        Group {
            if let url = RemoteMapperSupport.url(from: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholderView
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .background(DSColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholderView: some View {
        ZStack {
            DSColor.cardBackground
            Image(systemName: fallbackSystemImage)
                .font(.title3)
                .foregroundStyle(DSColor.subtitle)
        }
    }
}

struct DSAvatarView: View {
    let urlString: String?
    var size: CGFloat = 44
    var fallbackSystemImage: String = "person.crop.circle.fill"

    var body: some View {
        Group {
            if let url = RemoteMapperSupport.url(from: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholder
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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
}
