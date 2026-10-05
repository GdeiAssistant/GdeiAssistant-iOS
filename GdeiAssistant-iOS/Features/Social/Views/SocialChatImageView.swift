import SwiftUI
import UIKit

/// Authenticated DM image bubble/viewer. Never uses naked AsyncImage for chat-image paths.
struct SocialChatImageView: View {
    let remoteURL: String?
    let localData: Data?
    var maxWidth: CGFloat = 220
    var maxHeight: CGFloat = 220
    var fitEntireImage = false

    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var sessionState: SessionState
    @State private var image: UIImage?
    @State private var failed = false
    @State private var attempt = 0

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: fitEntireImage ? .fit : .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DSColor.cardBackground)
                    if failed {
                        Button(localizedString("common.retry")) { attempt += 1 }
                            .frame(minWidth: 44, minHeight: 44)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .frame(width: maxWidth, height: maxHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: cacheKey) {
            await reload()
        }
        .onDisappear { image = nil }
    }

    private var cacheKey: String {
        let source = remoteURL ?? localData.map { "local-\(SocialChatImageSupport.sha256Hex($0))" } ?? "none"
        return "\(sessionState.isLoggedIn)-\(sessionState.currentUser?.id ?? "")-\(attempt)-\(source)"
    }

    private func reload() async {
        image = nil
        failed = false
        let token = container.authManager.currentToken()
        if let localData, let local = UIImage(data: localData) {
            image = local
            return
        }
        if container.environment.dataSourceMode == .mock,
           let remoteURL,
           let data = (container.socialRepository as? SwitchingSocialRepository)?.demoImageData(for: remoteURL) {
            image = UIImage(data: data)
            failed = image == nil
            return
        }
        guard container.environment.dataSourceMode != .mock else {
            failed = true
            return
        }
        let loaded = await container.authenticatedImageLoader.chatImage(for: remoteURL)
        guard !Task.isCancelled, token == container.authManager.currentToken() else { return }
        image = loaded
        failed = loaded == nil
    }
}

struct SocialChatImagePreviewItem: Identifiable, Hashable {
    let id: String
    let remoteURL: String?
    let localData: Data?
}

struct SocialChatImagePreviewSheet: View {
    let item: SocialChatImagePreviewItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                SocialChatImageView(
                    remoteURL: item.remoteURL,
                    localData: item.localData,
                    maxWidth: UIScreen.main.bounds.width - 32,
                    maxHeight: UIScreen.main.bounds.height * 0.7,
                    fitEntireImage: true
                )
            }
            .navigationTitle(localizedString("social.chat.imagePreview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedString("common.cancel")) { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }
}
