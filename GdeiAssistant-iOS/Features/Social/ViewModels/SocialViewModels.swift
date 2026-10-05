import Foundation
import Combine
import UIKit

enum ChatThreadLifecyclePhase {
    case active
    case inactive
}

@MainActor
final class SocialUserSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private var nextCursor: String?
    private var searchTask: Task<Void, Never>?

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func search() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await reload()
        }
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.searchUsers(query: query, cursor: nil, limit: 20)
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.search.failed")
        }
    }

    func loadMoreIfNeeded(currentItem: SocialUser?) async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        guard let currentItem, currentItem.id == users.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await repository.searchUsers(query: query, cursor: nextCursor, limit: 20)
            users = mergeUnique(users, page.items)
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.search.failed")
        }
    }

    private func mergeUnique(_ existing: [SocialUser], _ incoming: [SocialUser]) -> [SocialUser] {
        var seen = Set(existing.map(\.id))
        var result = existing
        for item in incoming where !seen.contains(item.id) {
            seen.insert(item.id)
            result.append(item)
        }
        return result
    }
}

@MainActor
final class SocialPublicProfileViewModel: ObservableObject {
    @Published private(set) var user: SocialUser?
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var openedConversationID: String?

    let userID: String
    private let repository: any SocialRepository

    init(userID: String, repository: any SocialRepository) {
        self.userID = userID
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            user = try await repository.fetchUser(id: userID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.profile.loadFailed")
        }
    }

    func toggleFollow() async {
        guard let current = user, !current.isSelf else { return }
        isMutating = true
        defer { isMutating = false }
        do {
            user = current.isFollowing
                ? try await repository.unfollow(userID: current.id)
                : try await repository.follow(userID: current.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func toggleBlock() async {
        guard let current = user, !current.isSelf else { return }
        isMutating = true
        defer { isMutating = false }
        do {
            if current.blockedByMe {
                _ = try await repository.unblock(userID: current.id)
            } else {
                _ = try await repository.block(userID: current.id)
            }
            user = try await repository.fetchUser(id: current.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func openConversation() async {
        guard let current = user, current.canMessage else {
            infoMessage = localizedString("social.chat.permissionDenied")
            return
        }
        isMutating = true
        defer { isMutating = false }
        do {
            let conversation = try await repository.createConversation(peerID: current.id)
            openedConversationID = conversation.id
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.openFailed")
        }
    }
}

@MainActor
final class SocialRelationshipListViewModel: ObservableObject {
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    let userID: String
    let kind: SocialRelationshipKind
    private let repository: any SocialRepository
    private var nextCursor: String?

    init(userID: String, kind: SocialRelationshipKind, repository: any SocialRepository) {
        self.userID = userID
        self.kind = kind
        self.repository = repository
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.fetchRelationships(
                userID: userID,
                kind: kind,
                cursor: nil,
                limit: 20
            )
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.list.loadFailed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchRelationships(
                userID: userID,
                kind: kind,
                cursor: nextCursor,
                limit: 20
            )
            var seen = Set(users.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                users.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.list.loadFailed")
        }
    }
}

@MainActor
final class SocialBlockListViewModel: ObservableObject {
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private var nextCursor: String?

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.fetchBlocks(cursor: nil, limit: 20)
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.blockList.loadFailed")
        }
    }

    func unblock(_ user: SocialUser) async {
        do {
            _ = try await repository.unblock(userID: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchBlocks(cursor: nextCursor, limit: 20)
            var seen = Set(users.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                users.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.blockList.loadFailed")
        }
    }
}

@MainActor
final class DirectMessagePrivacyViewModel: ObservableObject {
    @Published var policy: DirectMessagePolicy = .mutual
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: any SocialRepository

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            policy = try await repository.fetchPrivacy().dmPolicy
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.dmPolicy.loadFailed")
        }
    }

    func update(_ next: DirectMessagePolicy) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            policy = try await repository.updatePrivacy(next).dmPolicy
            successMessage = localizedString("social.dmPolicy.updateSuccess")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.dmPolicy.updateFailed")
        }
    }
}

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published private(set) var conversations: [ConversationSummary] = []
    @Published private(set) var unreadTotal = 0
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private let realtimeManager: any SocialRealtimeManaging
    private var nextCursor: String?
    private var pollTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?

    init(repository: any SocialRepository, realtimeManager: any SocialRealtimeManaging) {
        self.repository = repository
        self.realtimeManager = realtimeManager
    }

    func start() async {
        await reload()
        startPolling()
        observeRealtime()
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        eventTask?.cancel()
        eventTask = nil
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            conversations = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            unreadTotal = unread.total
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.conversations.loadFailed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchConversations(cursor: nextCursor, limit: 20)
            var seen = Set(conversations.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                conversations.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.conversations.loadFailed")
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self, !Task.isCancelled else { return }
                await self.reloadQuietly()
            }
        }
    }

    private func observeRealtime() {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            guard let self else { return }
            var lastEvent = self.realtimeManager.latestEvent
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                let current = self.realtimeManager.latestEvent
                if current != lastEvent {
                    lastEvent = current
                    await self.reloadQuietly()
                }
            }
        }
    }

    private func reloadQuietly() async {
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            conversations = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            unreadTotal = unread.total
        } catch {
            // Keep existing list on background refresh failure.
        }
    }
}

@MainActor
final class ChatThreadViewModel: ObservableObject {
    @Published private(set) var conversation: ConversationSummary?
    @Published private(set) var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published private(set) var draftImagePreview: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published private(set) var hasMoreEarlier = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    let conversationID: String
    private let repository: any SocialRepository
    private let realtimeManager: any SocialRealtimeManaging
    private var earlierCursor: String?
    private var pollTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var lastMarkedReadSeq: String?
    private var resolvedCurrentUserID: String?
    private var isPageVisible = false
    private var allowsForegroundWork = false
    private let maxNewerPullPages = 8
    /// Pending/failed IMAGE payloads keyed by original clientMessageId for multipart retry.
    private var localImageDataByClientID: [String: Data] = [:]
    private var draftImageData: Data?
    private var sessionGeneration: UInt64 = 0
    private let tokenProvider: @MainActor () -> String?

    init(
        conversationID: String,
        repository: any SocialRepository,
        realtimeManager: any SocialRealtimeManaging,
        tokenProvider: @escaping @MainActor () -> String? = { nil }
    ) {
        self.conversationID = conversationID
        self.repository = repository
        self.realtimeManager = realtimeManager
        self.tokenProvider = tokenProvider
    }

    var currentUserID: String? {
        resolvedCurrentUserID
    }

    var canSendImage: Bool {
        (conversation?.canSend == true) && (conversation?.imageMessagingEnabled == true)
    }

    func localImageData(for clientMessageId: String) -> Data? {
        localImageDataByClientID[clientMessageId]
    }

    func setDraftImage(_ image: UIImage?) {
        guard isPageVisible else { return }
        guard let image else {
            clearDraftImage()
            return
        }
        guard let asset = SocialChatImageSupport.jpegUploadAsset(
            from: image,
            fileName: "chat-draft.jpg"
        ) else {
            infoMessage = localizedString("social.chat.imageTooLarge")
            clearDraftImage()
            return
        }
        draftImageData = asset.data
        draftImagePreview = UIImage(data: asset.data) ?? image
    }

    func clearDraftImage() {
        draftImageData = nil
        draftImagePreview = nil
    }

    func start() async {
        isPageVisible = true
        allowsForegroundWork = true
        let generation = sessionGeneration
        let token = tokenProvider()
        if resolvedCurrentUserID == nil {
            let userID = try? await repository.fetchMe().id
            guard isCurrentSession(generation, token: token) else { return }
            resolvedCurrentUserID = userID
        }
        await reload()
        guard isPageVisible, allowsForegroundWork else { return }
        startPolling()
        observeRealtime()
    }

    func stop() {
        sessionGeneration &+= 1
        isPageVisible = false
        allowsForegroundWork = false
        pollTask?.cancel()
        pollTask = nil
        eventTask?.cancel()
        eventTask = nil
        clearDraftImage()
        localImageDataByClientID.removeAll()
        messages.removeAll()
        conversation = nil
        resolvedCurrentUserID = nil
        draft = ""
        isLoading = false
        isSending = false
        errorMessage = nil
        infoMessage = nil
    }

    private func isCurrentSession(_ generation: UInt64, token: String?) -> Bool {
        isPageVisible && sessionGeneration == generation && tokenProvider() == token
    }

    func handleScenePhase(_ phase: ChatThreadLifecyclePhase) {
        switch phase {
        case .active:
            guard isPageVisible else { return }
            allowsForegroundWork = true
            if pollTask == nil {
                startPolling()
            }
            if eventTask == nil {
                observeRealtime()
            }
            Task { [weak self] in
                guard let self else { return }
                await self.pullNewerMessages()
            }
        case .inactive:
            allowsForegroundWork = false
            pollTask?.cancel()
            pollTask = nil
            eventTask?.cancel()
            eventTask = nil
        }
    }

    func reload() async {
        let generation = sessionGeneration
        let token = tokenProvider()
        isLoading = true
        errorMessage = nil
        defer { if isCurrentSession(generation, token: token) { isLoading = false } }
        do {
            async let conversationTask = repository.fetchConversation(id: conversationID)
            async let messagesTask = repository.fetchMessages(
                conversationID: conversationID,
                beforeSeq: nil,
                afterSeq: nil,
                limit: 20
            )
            let summary = try await conversationTask
            let page = try await messagesTask
            guard isCurrentSession(generation, token: token) else { return }
            conversation = summary
            messages = ChatMessageMerge.merge(page.items)
            earlierCursor = page.nextCursor
            hasMoreEarlier = page.hasMore
            if isPageVisible, allowsForegroundWork {
                await markVisibleAsRead()
            }
        } catch {
            guard isCurrentSession(generation, token: token) else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.loadFailed")
        }
    }

    func loadEarlier() async {
        let generation = sessionGeneration
        let token = tokenProvider()
        guard hasMoreEarlier, let earlierCursor else { return }
        do {
            let page = try await repository.fetchMessages(
                conversationID: conversationID,
                beforeSeq: earlierCursor,
                afterSeq: nil,
                limit: 20
            )
            guard isCurrentSession(generation, token: token) else { return }
            messages = ChatMessageMerge.merge(page.items + messages)
            self.earlierCursor = page.nextCursor
            hasMoreEarlier = page.hasMore
        } catch {
            guard isCurrentSession(generation, token: token) else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.loadFailed")
        }
    }

    func send() async {
        guard isPageVisible, !isSending else { return }
        let generation = sessionGeneration
        let token = tokenProvider()
        if draftImageData != nil {
            await sendDraftImage()
            return
        }
        let content = draft
        guard let sanitized = SocialRemoteMapper.sanitizedMessageContent(content) else {
            infoMessage = localizedString("social.chat.invalidContent")
            return
        }
        guard conversation?.canSend == true else {
            infoMessage = localizedString("social.chat.permissionDenied")
            await refreshPermissions()
            return
        }

        guard let senderId = currentUserID else { return }
        let clientMessageID = UUID().uuidString
        let pending = ChatMessage(
            id: "pending-\(clientMessageID)",
            conversationId: conversationID,
            seq: "",
            senderId: senderId,
            clientMessageId: clientMessageID,
            type: .text,
            content: sanitized,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            deliveryState: .pending
        )
        messages = ChatMessageMerge.merge(messages + [pending])
        draft = ""
        isSending = true
        defer { if isCurrentSession(generation, token: token) { isSending = false } }

        do {
            let sent = try await repository.sendMessage(
                conversationID: conversationID,
                clientMessageID: clientMessageID,
                content: sanitized
            )
            guard isCurrentSession(generation, token: token) else { return }
            messages = ChatMessageMerge.replaceLocalBubble(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID,
                with: sent
            )
            await refreshPermissions()
        } catch {
            guard isCurrentSession(generation, token: token) else { return }
            if ChatMessageMerge.hasCommittedSend(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID
            ) {
                return
            }
            messages = ChatMessageMerge.updateLocalBubbleState(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID,
                deliveryState: .failed
            )
            if let networkError = error as? NetworkError,
               networkError.errorCode == SocialErrorCode.privacyRestricted
                || networkError.errorCode == SocialErrorCode.contactUnavailable {
                draft = sanitized
                await refreshPermissions()
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.sendFailed")
        }
    }

    func sendDraftImage() async {
        guard isPageVisible, !isSending else { return }
        let generation = sessionGeneration
        let token = tokenProvider()
        guard let imageData = draftImageData else { return }
        guard canSendImage else {
            infoMessage = conversation?.imageMessagingEnabled == false
                ? localizedString("social.chat.imageDisabled")
                : localizedString("social.chat.permissionDenied")
            await refreshPermissions()
            return
        }

        guard let senderId = currentUserID else { return }
        let clientMessageID = UUID().uuidString
        localImageDataByClientID[clientMessageID] = imageData
        let pending = ChatMessage(
            id: "pending-\(clientMessageID)",
            conversationId: conversationID,
            seq: "",
            senderId: senderId,
            clientMessageId: clientMessageID,
            type: .image,
            content: "",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            image: nil,
            deliveryState: .pending
        )
        messages = ChatMessageMerge.merge(messages + [pending])
        clearDraftImage()
        isSending = true
        defer { if isCurrentSession(generation, token: token) { isSending = false } }

        await performImageSend(
            senderId: senderId,
            clientMessageID: clientMessageID,
            imageData: imageData
        )
    }

    func retry(_ message: ChatMessage) async {
        guard isPageVisible else { return }
        let generation = sessionGeneration
        let token = tokenProvider()
        guard message.deliveryState == .failed else { return }
        let senderId = message.senderId
        messages = ChatMessageMerge.updateLocalBubbleState(
            in: messages,
            senderId: senderId,
            clientMessageId: message.clientMessageId,
            deliveryState: .pending
        )

        if message.type == .image {
            guard let imageData = localImageDataByClientID[message.clientMessageId] else {
                errorMessage = localizedString("social.chat.imageRetryMissing")
                messages = ChatMessageMerge.updateLocalBubbleState(
                    in: messages,
                    senderId: senderId,
                    clientMessageId: message.clientMessageId,
                    deliveryState: .failed
                )
                return
            }
            await performImageSend(
                senderId: senderId,
                clientMessageID: message.clientMessageId,
                imageData: imageData
            )
            return
        }

        do {
            let sent = try await repository.sendMessage(
                conversationID: conversationID,
                clientMessageID: message.clientMessageId,
                content: message.content
            )
            guard isCurrentSession(generation, token: token) else { return }
            messages = ChatMessageMerge.replaceLocalBubble(
                in: messages,
                senderId: senderId,
                clientMessageId: message.clientMessageId,
                with: sent
            )
        } catch {
            guard isCurrentSession(generation, token: token) else { return }
            if ChatMessageMerge.hasCommittedSend(
                in: messages,
                senderId: senderId,
                clientMessageId: message.clientMessageId
            ) {
                return
            }
            messages = ChatMessageMerge.updateLocalBubbleState(
                in: messages,
                senderId: senderId,
                clientMessageId: message.clientMessageId,
                deliveryState: .failed
            )
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.sendFailed")
        }
    }

    private func performImageSend(
        senderId: String,
        clientMessageID: String,
        imageData: Data
    ) async {
        let generation = sessionGeneration
        let token = tokenProvider()
        do {
            let sent = try await repository.sendImageMessage(
                conversationID: conversationID,
                clientMessageID: clientMessageID,
                imageData: imageData,
                fileName: "chat-\(clientMessageID).jpg",
                mimeType: "image/jpeg"
            )
            guard isCurrentSession(generation, token: token) else { return }
            messages = ChatMessageMerge.replaceLocalBubble(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID,
                with: sent
            )
            localImageDataByClientID.removeValue(forKey: clientMessageID)
            await refreshPermissions()
        } catch {
            guard isCurrentSession(generation, token: token) else { return }
            if ChatMessageMerge.hasCommittedSend(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID
            ) {
                // WS/REST already confirmed SENT — keep original client ID, do not demote.
                localImageDataByClientID.removeValue(forKey: clientMessageID)
                return
            }
            messages = ChatMessageMerge.updateLocalBubbleState(
                in: messages,
                senderId: senderId,
                clientMessageId: clientMessageID,
                deliveryState: .failed
            )
            if let networkError = error as? NetworkError,
               networkError.errorCode == SocialErrorCode.privacyRestricted
                || networkError.errorCode == SocialErrorCode.contactUnavailable {
                await refreshPermissions()
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.sendFailed")
        }
    }

    func markVisibleAsRead() async {
        guard isPageVisible, allowsForegroundWork else { return }
        let generation = sessionGeneration
        let token = tokenProvider()
        guard let seq = ChatMessageMerge.latestCommittedPeerSeq(
            messages,
            excludingSenderId: currentUserID
        ) else { return }
        if lastMarkedReadSeq == seq { return }
        do {
            let state = try await repository.markRead(conversationID: conversationID, lastReadSeq: seq)
            guard isCurrentSession(generation, token: token), allowsForegroundWork else { return }
            lastMarkedReadSeq = state.lastReadSeq
            if var conversation {
                conversation = ConversationSummary(
                    id: conversation.id,
                    peer: conversation.peer,
                    lastMessage: conversation.lastMessage,
                    updatedAt: conversation.updatedAt,
                    unreadCount: state.unreadCount,
                    lastReadSeq: state.lastReadSeq,
                    canSend: conversation.canSend,
                    sendPermissionReason: conversation.sendPermissionReason,
                    imageMessagingEnabled: conversation.imageMessagingEnabled
                )
                self.conversation = conversation
            }
        } catch {
            // Visible-read sync is best-effort.
        }
    }

    private func refreshPermissions() async {
        let generation = sessionGeneration
        let token = tokenProvider()
        let summary = try? await repository.fetchConversation(id: conversationID)
        guard isCurrentSession(generation, token: token) else { return }
        conversation = summary
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard let self, !Task.isCancelled else { return }
                guard self.isPageVisible, self.allowsForegroundWork else { return }
                await self.pullNewerMessages()
            }
        }
    }

    private func observeRealtime() {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            guard let self else { return }
            var lastEvent = self.realtimeManager.latestEvent
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard self.isPageVisible, self.allowsForegroundWork else { return }
                let current = self.realtimeManager.latestEvent
                guard current != lastEvent else { continue }
                lastEvent = current
                switch current {
                case .messageCreated(let conversationId, _, _) where conversationId == self.conversationID:
                    await self.pullNewerMessages()
                case .conversationRead(let conversationId, _, _) where conversationId == self.conversationID:
                    await self.refreshPermissions()
                case .ready, .socialChanged, .disconnected:
                    await self.pullNewerMessages()
                    await self.refreshPermissions()
                default:
                    break
                }
            }
        }
    }

    private func pullNewerMessages() async {
        guard isPageVisible, allowsForegroundWork else { return }
        let generation = sessionGeneration
        let token = tokenProvider()
        var afterSeq = ChatMessageMerge.latestCommittedSeq(messages)
        var pagesPulled = 0
        do {
            while pagesPulled < maxNewerPullPages {
                guard isPageVisible, allowsForegroundWork else { return }
                pagesPulled += 1
                let page = try await repository.fetchMessages(
                    conversationID: conversationID,
                    beforeSeq: nil,
                    afterSeq: afterSeq,
                    limit: 50
                )
                guard isCurrentSession(generation, token: token), allowsForegroundWork else { return }
                if !page.items.isEmpty {
                    messages = ChatMessageMerge.merge(messages + page.items)
                    afterSeq = ChatMessageMerge.latestCommittedSeq(messages) ?? afterSeq
                }
                if !page.hasMore || page.items.isEmpty {
                    break
                }
            }
            if isPageVisible, allowsForegroundWork {
                await markVisibleAsRead()
                await refreshPermissions()
            }
        } catch {
            // Keep current messages on background sync failure.
        }
    }
}

@MainActor
final class SocialMeSummaryViewModel: ObservableObject {
    @Published private(set) var me: SocialUser?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            me = try await repository.fetchMe()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.profile.loadFailed")
        }
    }
}
