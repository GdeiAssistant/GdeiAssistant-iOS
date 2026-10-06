import Foundation
import Combine
import UIKit

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
