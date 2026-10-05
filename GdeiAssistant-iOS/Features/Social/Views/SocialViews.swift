import SwiftUI
import PhotosUI
import UIKit

struct SocialUserSearchView: View {
    @StateObject private var viewModel: SocialUserSearchViewModel

    init(viewModel: SocialUserSearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                TextField(localizedString("social.search.placeholder"), text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.query) { _, _ in
                        viewModel.search()
                    }
            }

            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView(localizedString("common.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(DSColor.danger)
            } else if viewModel.users.isEmpty {
                Text(localizedString("social.search.empty"))
                    .foregroundStyle(DSColor.subtitle)
            } else {
                ForEach(viewModel.users) { user in
                    NavigationLink {
                        SocialPublicProfileRoute(userID: user.id)
                    } label: {
                        SocialUserRow(user: user)
                    }
                    .task {
                        await viewModel.loadMoreIfNeeded(currentItem: user)
                    }
                }
            }
        }
        .navigationTitle(localizedString("social.search.title"))
        .task {
            await viewModel.reload()
        }
    }
}

struct SocialPublicProfileView: View {
    @StateObject private var viewModel: SocialPublicProfileViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var conversationRoute: String?

    init(viewModel: SocialPublicProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.user == nil {
                DSLoadingView(text: localizedString("social.profile.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.user == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 14) {
                            SocialAvatarView(urlString: user.avatarURL, size: 76)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.nickname)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(DSColor.title)
                                    .lineLimit(1)
                                Text(user.relationshipBadgeText)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.primary)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 76)

                        if let introduction = user.introduction, !introduction.isEmpty {
                            Text(introduction)
                                .font(.body)
                                .foregroundStyle(DSColor.subtitle)
                        }

                        HStack(spacing: 18) {
                            statLink(
                                title: localizedString("social.relationship.following"),
                                value: user.followingCount,
                                kind: .following,
                                userID: user.id
                            )
                            statLink(
                                title: localizedString("social.relationship.followers"),
                                value: user.followerCount,
                                kind: .followers,
                                userID: user.id
                            )
                            statLink(
                                title: localizedString("social.relationship.friends"),
                                value: user.friendCount,
                                kind: .friends,
                                userID: user.id
                            )
                        }

                        if !user.isSelf {
                            HStack(spacing: 12) {
                                DSButton(
                                    title: user.isFollowing
                                        ? localizedString("social.action.unfollow")
                                        : localizedString("social.action.follow"),
                                    icon: user.isFollowing ? "person.badge.minus" : "person.badge.plus",
                                    variant: .primary
                                ) {
                                    Task { await viewModel.toggleFollow() }
                                }
                                .disabled(viewModel.isMutating || user.blockedByMe)

                                DSButton(
                                    title: localizedString("social.action.message"),
                                    icon: "bubble.left",
                                    variant: .secondary
                                ) {
                                    Task {
                                        await viewModel.openConversation()
                                        if let conversationID = viewModel.openedConversationID {
                                            conversationRoute = conversationID
                                        }
                                    }
                                }
                                .disabled(viewModel.isMutating || !user.canMessage)
                            }

                            Button {
                                Task { await viewModel.toggleBlock() }
                            } label: {
                                Text(user.blockedByMe
                                      ? localizedString("social.action.unblock")
                                      : localizedString("social.action.block"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.danger)
                            }
                            .disabled(viewModel.isMutating)
                        }
                    }
                    .padding(16)
                }
                .background(DSColor.background.ignoresSafeArea())
            }
        }
        .navigationTitle(localizedString("social.profile.title"))
        .navigationDestination(item: $conversationRoute) { conversationID in
            ChatThreadView(
                viewModel: container.makeChatThreadViewModel(conversationID: conversationID)
            )
        }
        .task {
            await viewModel.load()
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: { viewModel.infoMessage != nil || viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.infoMessage = nil; viewModel.errorMessage = nil } }
        )) {
            Button(localizedString("common.understood"), role: .cancel) {}
        } message: {
            Text(viewModel.infoMessage ?? viewModel.errorMessage ?? "")
        }
    }

    private func statLink(
        title: String,
        value: Int,
        kind: SocialRelationshipKind,
        userID: String
    ) -> some View {
        NavigationLink {
            SocialRelationshipListView(
                viewModel: container.makeSocialRelationshipListViewModel(userID: userID, kind: kind)
            )
        } label: {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct SocialPublicProfileRoute: View {
    @EnvironmentObject private var container: AppContainer
    let userID: String

    var body: some View {
        SocialPublicProfileView(viewModel: container.makeSocialPublicProfileViewModel(userID: userID))
    }
}

struct SocialRelationshipListView: View {
    @StateObject private var viewModel: SocialRelationshipListViewModel

    init(viewModel: SocialRelationshipListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView(localizedString("common.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
                Text(errorMessage).foregroundStyle(DSColor.danger)
            } else if viewModel.users.isEmpty {
                Text(localizedString("social.list.empty")).foregroundStyle(DSColor.subtitle)
            } else {
                ForEach(viewModel.users) { user in
                    NavigationLink {
                        SocialPublicProfileRoute(userID: user.id)
                    } label: {
                        SocialUserRow(user: user)
                    }
                    .onAppear {
                        if user.id == viewModel.users.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.kind.title)
        .task { await viewModel.reload() }
    }
}

struct SocialBlockListView: View {
    @StateObject private var viewModel: SocialBlockListViewModel

    init(viewModel: SocialBlockListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView(localizedString("common.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
                Text(errorMessage).foregroundStyle(DSColor.danger)
            } else if viewModel.users.isEmpty {
                Text(localizedString("social.blockList.empty")).foregroundStyle(DSColor.subtitle)
            } else {
                ForEach(viewModel.users) { user in
                    HStack {
                        SocialUserRow(user: user)
                        Spacer()
                        Button(localizedString("social.action.unblock")) {
                            Task { await viewModel.unblock(user) }
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .onAppear {
                        if user.id == viewModel.users.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
        }
        .navigationTitle(localizedString("social.blockList.title"))
        .task { await viewModel.reload() }
    }
}

struct DirectMessagePrivacyView: View {
    @StateObject private var viewModel: DirectMessagePrivacyViewModel

    init(viewModel: DirectMessagePrivacyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section(localizedString("social.dmPolicy.section")) {
                ForEach(DirectMessagePolicy.allCases) { policy in
                    Button {
                        Task { await viewModel.update(policy) }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(policy.title)
                                    .foregroundStyle(DSColor.title)
                                Text(policy.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            Spacer()
                            if viewModel.policy == policy {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DSColor.primary)
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(DSColor.danger)
            }
        }
        .navigationTitle(localizedString("social.dmPolicy.title"))
        .overlay {
            if viewModel.isLoading {
                ProgressView(localizedString("common.loading"))
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .task { await viewModel.load() }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button(localizedString("common.understood"), role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
}

struct ConversationListView: View {
    @StateObject private var viewModel: ConversationListViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: ConversationListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.unreadTotal > 0 {
                Section {
                    Text(String(format: localizedString("social.conversations.unreadTotal"), viewModel.unreadTotal))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DSColor.primary)
                }
            }

            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView(localizedString("common.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.conversations.isEmpty {
                Text(errorMessage).foregroundStyle(DSColor.danger)
            } else if viewModel.conversations.isEmpty {
                Text(localizedString("social.conversations.empty")).foregroundStyle(DSColor.subtitle)
            } else {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink {
                        ChatThreadView(
                            viewModel: container.makeChatThreadViewModel(conversationID: conversation.id)
                        )
                    } label: {
                        conversationRow(conversation)
                    }
                    .onAppear {
                        if conversation.id == viewModel.conversations.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
        }
        .navigationTitle(localizedString("social.conversations.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SocialUserSearchView(viewModel: container.makeSocialUserSearchViewModel())
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
            }
        }
        .refreshable { await viewModel.reload() }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private func conversationRow(_ conversation: ConversationSummary) -> some View {
        HStack(alignment: .center, spacing: 12) {
            SocialAvatarView(urlString: conversation.peer.avatarURL, size: 48)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.peer.nickname)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(SocialDisplayTime.format(conversation.updatedAt))
                        .font(.caption2)
                        .foregroundStyle(DSColor.subtitle)
                }
                Text(conversation.lastMessage?.previewText ?? localizedString("social.conversations.noMessage"))
                    .font(conversation.unreadCount > 0 ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(conversation.unreadCount > 0 ? DSColor.title : DSColor.subtitle)
                    .lineLimit(2)
            }
            if conversation.unreadCount > 0 {
                Text(conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(DSColor.primary)
                    .clipShape(Capsule())
                    .accessibilityLabel(
                        String(format: localizedString("social.conversations.unreadTotal"), conversation.unreadCount)
                    )
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
    }
}

struct ChatThreadView: View {
    @StateObject private var viewModel: ChatThreadViewModel
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var container: AppContainer
    @State private var imageLoadTask: Task<Void, Never>?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var previewItem: SocialChatImagePreviewItem?

    init(viewModel: ChatThreadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                DSLoadingView(text: localizedString("social.chat.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.messages.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.reload() }
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.hasMoreEarlier {
                                Button(localizedString("social.chat.loadEarlier")) {
                                    Task { await viewModel.loadEarlier() }
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DSColor.primary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                            }
                            ForEach(viewModel.messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages) { previous, current in
                        switch ChatThreadAutoScroll.action(previous: previous, current: current) {
                        case .none:
                            break
                        case .scrollToBottom(let messageID):
                            withAnimation {
                                proxy.scrollTo(messageID, anchor: .bottom)
                            }
                        case .preserve(let messageID):
                            proxy.scrollTo(messageID, anchor: .top)
                        }
                        Task { await viewModel.markVisibleAsRead() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                if let preview = viewModel.draftImagePreview {
                    draftImageBar(preview)
                }
                composer
            }
            .background(DSColor.cardBackground)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    SocialAvatarView(
                        urlString: viewModel.conversation?.peer.avatarURL,
                        size: 30
                    )
                    Text(viewModel.conversation?.peer.nickname ?? localizedString("social.chat.title"))
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            imageLoadTask?.cancel()
            imageLoadTask = nil
            photoPickerItem = nil
            previewItem = nil
            viewModel.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                viewModel.handleScenePhase(.active)
            case .inactive, .background:
                viewModel.handleScenePhase(.inactive)
            @unknown default:
                viewModel.handleScenePhase(.inactive)
            }
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            imageLoadTask?.cancel()
            let token = container.authManager.currentToken()
            imageLoadTask = Task {
                let data = try? await item.loadTransferable(type: Data.self)
                guard !Task.isCancelled, token == container.authManager.currentToken() else { return }
                if let data, let image = UIImage(data: data) {
                    viewModel.setDraftImage(image)
                } else {
                    viewModel.infoMessage = localizedString("social.chat.imageInvalid")
                }
                photoPickerItem = nil
            }
        }
        .sheet(item: $previewItem) { item in
            SocialChatImagePreviewSheet(item: item)
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: { viewModel.infoMessage != nil || viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.infoMessage = nil; viewModel.errorMessage = nil } }
        )) {
            Button(localizedString("common.understood"), role: .cancel) {}
        } message: {
            Text(viewModel.infoMessage ?? viewModel.errorMessage ?? "")
        }
    }

    private func draftImageBar(_ preview: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: preview)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(localizedString("social.chat.imageReady"))
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
            Spacer(minLength: 0)
            Button(localizedString("common.cancel")) {
                viewModel.clearDraftImage()
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if viewModel.canSendImage {
                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DSColor.primary)
                        .frame(width: 44, height: 44)
                }
                .disabled(viewModel.isSending || viewModel.conversation?.canSend == false)
                .accessibilityLabel(localizedString("social.chat.pickImage"))
            }

            TextField(localizedString("social.chat.placeholder"), text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.conversation?.canSend == false || viewModel.draftImagePreview != nil)

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DSColor.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(viewModel.isSending || !canTapSend)
            .accessibilityLabel(localizedString("social.chat.send"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DSColor.cardBackground)
    }

    private var canTapSend: Bool {
        if viewModel.draftImagePreview != nil { return true }
        return !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isMine = message.senderId == viewModel.currentUserID
        return HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 48) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 5) {
                Group {
                    switch message.type {
                    case .image:
                        Button {
                            previewItem = SocialChatImagePreviewItem(
                                id: message.id,
                                remoteURL: message.image?.url,
                                localData: viewModel.localImageData(for: message.clientMessageId)
                            )
                        } label: {
                            SocialChatImageView(
                                remoteURL: message.image?.url,
                                localData: viewModel.localImageData(for: message.clientMessageId)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                if message.deliveryState == .pending {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(8)
                                }
                            }
                            .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                    case .text:
                        Text(message.content)
                            .font(.body)
                            .foregroundStyle(isMine ? Color.white : DSColor.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(isMine ? DSColor.primary : DSColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(isMine ? 0.08 : 0.04), radius: 2, y: 1)
                    }
                }

                HStack(spacing: 6) {
                    Text(SocialDisplayTime.format(message.createdAt))
                        .font(.caption2)
                        .foregroundStyle(DSColor.subtitle)
                    if isMine {
                        Text(deliveryText(message.deliveryState))
                            .font(.caption2)
                            .foregroundStyle(message.deliveryState == .failed ? DSColor.danger : DSColor.subtitle)
                        if message.deliveryState == .failed {
                            Button(localizedString("common.retry")) {
                                Task { await viewModel.retry(message) }
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DSColor.primary)
                            .frame(minHeight: 44)
                        }
                    }
                }
            }
            if !isMine { Spacer(minLength: 48) }
        }
    }

    private func deliveryText(_ state: ChatDeliveryState) -> String {
        switch state {
        case .pending:
            return localizedString("social.chat.state.pending")
        case .sent:
            return localizedString("social.chat.state.sent")
        case .failed:
            return localizedString("social.chat.state.failed")
        }
    }
}

struct SocialUserRow: View {
    let user: SocialUser

    var body: some View {
        HStack(spacing: 12) {
            SocialAvatarView(urlString: user.avatarURL, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname)
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                if let introduction = user.introduction, !introduction.isEmpty {
                    Text(introduction)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
