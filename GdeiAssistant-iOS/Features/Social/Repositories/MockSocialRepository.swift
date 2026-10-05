import Foundation
import UIKit

@MainActor
final class MockSocialRepository: SocialRepository {
    private var users: [String: SocialUser]
    private var blocks: Set<String> = []
    private var follows: Set<FollowEdge> = [
        FollowEdge(followerID: MockSocialSeed.meID, followeeID: MockSocialSeed.aliceID),
        FollowEdge(followerID: MockSocialSeed.aliceID, followeeID: MockSocialSeed.meID),
        FollowEdge(followerID: MockSocialSeed.bobID, followeeID: MockSocialSeed.meID),
        FollowEdge(followerID: MockSocialSeed.meID, followeeID: MockSocialSeed.carolID)
    ]
    private var privacy = DirectMessagePrivacy(dmPolicy: .mutual)
    private var conversations: [String: MutableConversation]
    private var messagesByConversation: [String: [ChatMessage]]
    private var imageBytesByMessageID: [String: Data] = [:]
    private var imageSHAByClientID: [String: String] = [:]

    init() {
        let seedUsers = MockSocialSeed.users
        users = Dictionary(uniqueKeysWithValues: seedUsers.map { ($0.id, $0) })
        conversations = MockSocialSeed.conversations
        messagesByConversation = MockSocialSeed.messages
        imageBytesByMessageID = MockSocialSeed.seedImageBytes
        refreshDerivedUserStates()
    }

    func fetchMe() async throws -> SocialUser {
        try await delay()
        return try requireUser(MockSocialSeed.meID)
    }

    func searchUsers(query: String, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await delay()
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = users.values
            .filter { $0.id != MockSocialSeed.meID }
            .filter { user in
                guard !needle.isEmpty else { return true }
                return user.nickname.lowercased().contains(needle) || user.id.lowercased().contains(needle)
            }
            .sorted { $0.nickname.localizedCompare($1.nickname) == .orderedAscending }
        return page(filtered, cursor: cursor, limit: limit)
    }

    func fetchUser(id: String) async throws -> SocialUser {
        try await delay()
        return try requireUser(id)
    }

    func fetchRelationships(
        userID: String,
        kind: SocialRelationshipKind,
        cursor: String?,
        limit: Int
    ) async throws -> SocialPage<SocialUser> {
        try await delay()
        _ = try requireUser(userID)
        let ids: [String]
        switch kind {
        case .following:
            ids = follows.filter { $0.followerID == userID }.map(\.followeeID)
        case .followers:
            ids = follows.filter { $0.followeeID == userID }.map(\.followerID)
        case .friends:
            let outgoing = Set(follows.filter { $0.followerID == userID }.map(\.followeeID))
            let incoming = Set(follows.filter { $0.followeeID == userID }.map(\.followerID))
            ids = Array(outgoing.intersection(incoming))
        }
        let items = ids.compactMap { users[$0] }.sorted { $0.nickname.localizedCompare($1.nickname) == .orderedAscending }
        return page(items, cursor: cursor, limit: limit)
    }

    func follow(userID: String) async throws -> SocialUser {
        try await delay()
        guard userID != MockSocialSeed.meID else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.error.invalidRequest"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }
        _ = try requireUser(userID)
        if blocks.contains(userID) {
            throw NetworkError.contract(
                statusCode: 403,
                message: localizedString("social.error.contactUnavailable"),
                errorCode: SocialErrorCode.contactUnavailable
            )
        }
        follows.insert(FollowEdge(followerID: MockSocialSeed.meID, followeeID: userID))
        refreshDerivedUserStates()
        return try requireUser(userID)
    }

    func unfollow(userID: String) async throws -> SocialUser {
        try await delay()
        _ = try requireUser(userID)
        follows.remove(FollowEdge(followerID: MockSocialSeed.meID, followeeID: userID))
        refreshDerivedUserStates()
        return try requireUser(userID)
    }

    func block(userID: String) async throws -> SocialBlockState {
        try await delay()
        guard userID != MockSocialSeed.meID else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.error.invalidRequest"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }
        _ = try requireUser(userID)
        blocks.insert(userID)
        follows.remove(FollowEdge(followerID: MockSocialSeed.meID, followeeID: userID))
        follows.remove(FollowEdge(followerID: userID, followeeID: MockSocialSeed.meID))
        refreshDerivedUserStates()
        return SocialBlockState(blocked: true)
    }

    func unblock(userID: String) async throws -> SocialBlockState {
        try await delay()
        _ = try requireUser(userID)
        blocks.remove(userID)
        refreshDerivedUserStates()
        return SocialBlockState(blocked: false)
    }

    func fetchBlocks(cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await delay()
        let items = blocks.compactMap { users[$0] }.sorted { $0.nickname.localizedCompare($1.nickname) == .orderedAscending }
        return page(items, cursor: cursor, limit: limit)
    }

    func fetchPrivacy() async throws -> DirectMessagePrivacy {
        try await delay()
        return privacy
    }

    func updatePrivacy(_ policy: DirectMessagePolicy) async throws -> DirectMessagePrivacy {
        try await delay()
        privacy = DirectMessagePrivacy(dmPolicy: policy)
        refreshDerivedUserStates()
        return privacy
    }

    func fetchUnreadCount() async throws -> SocialUnreadCount {
        try await delay()
        let total = conversations.values.reduce(0) { $0 + $1.unreadCount }
        return SocialUnreadCount(total: total)
    }

    func createConversation(peerID: String) async throws -> ConversationSummary {
        try await delay()
        let peer = try requireUser(peerID)
        guard peer.canMessage else {
            throw NetworkError.contract(
                statusCode: 403,
                message: localizedString("social.error.privacyRestricted"),
                errorCode: SocialErrorCode.privacyRestricted
            )
        }
        if let existing = conversations.values.first(where: { $0.peerID == peerID }) {
            return makeSummary(existing)
        }
        let conversationID = String((conversations.keys.compactMap(Int64.init).max() ?? 0) + 1)
        let mutable = MutableConversation(
            id: conversationID,
            peerID: peerID,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            unreadCount: 0,
            lastReadSeq: "0",
            lastSeq: 0,
            imageMessagingEnabled: true
        )
        conversations[conversationID] = mutable
        messagesByConversation[conversationID] = []
        return makeSummary(mutable)
    }

    func fetchConversations(cursor: String?, limit: Int) async throws -> SocialPage<ConversationSummary> {
        try await delay()
        let items = conversations.values
            .map(makeSummary)
            .sorted { $0.updatedAt > $1.updatedAt }
        return page(items, cursor: cursor, limit: limit)
    }

    func fetchConversation(id: String) async throws -> ConversationSummary {
        try await delay()
        guard let conversation = conversations[id] else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.conversationNotFound"),
                errorCode: SocialErrorCode.conversationNotFound
            )
        }
        return makeSummary(conversation)
    }

    func fetchMessages(
        conversationID: String,
        beforeSeq: String?,
        afterSeq: String?,
        limit: Int
    ) async throws -> SocialPage<ChatMessage> {
        try await delay()
        guard conversations[conversationID] != nil else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.conversationNotFound"),
                errorCode: SocialErrorCode.conversationNotFound
            )
        }
        let all = (messagesByConversation[conversationID] ?? []).sorted { $0.seqValue < $1.seqValue }
        let safeLimit = min(max(limit, 1), 50)
        if let beforeSeq, let before = Int64(beforeSeq) {
            let filtered = all.filter { $0.seqValue < before }
            let pageItems = Array(filtered.suffix(safeLimit))
            let next = pageItems.first?.seq
            return SocialPage(items: pageItems, nextCursor: next, hasMore: filtered.count > pageItems.count)
        }
        if let afterSeq, let after = Int64(afterSeq) {
            let filtered = all.filter { $0.seqValue > after }
            let pageItems = Array(filtered.prefix(safeLimit))
            let next = pageItems.last?.seq
            return SocialPage(items: pageItems, nextCursor: next, hasMore: filtered.count > pageItems.count)
        }
        let pageItems = Array(all.suffix(safeLimit))
        let next = pageItems.first?.seq
        return SocialPage(items: pageItems, nextCursor: next, hasMore: all.count > pageItems.count)
    }

    func sendMessage(
        conversationID: String,
        clientMessageID: String,
        content: String
    ) async throws -> ChatMessage {
        try await delay()
        guard var conversation = conversations[conversationID] else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.conversationNotFound"),
                errorCode: SocialErrorCode.conversationNotFound
            )
        }
        let peer = try requireUser(conversation.peerID)
        guard peer.canMessage else {
            throw NetworkError.contract(
                statusCode: 403,
                message: localizedString("social.error.privacyRestricted"),
                errorCode: SocialErrorCode.privacyRestricted
            )
        }
        guard let sanitized = SocialRemoteMapper.sanitizedMessageContent(content) else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.error.invalidRequest"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }

        var messages = messagesByConversation[conversationID] ?? []
        if let existing = messages.first(where: {
            $0.clientMessageId == clientMessageID && $0.senderId == MockSocialSeed.meID
        }) {
            if existing.type != .text || existing.content != sanitized {
                throw NetworkError.contract(
                    statusCode: 409,
                    message: localizedString("social.error.clientMessageConflict"),
                    errorCode: SocialErrorCode.clientMessageConflict
                )
            }
            return existing.updating(deliveryState: .sent)
        }

        conversation.lastSeq += 1
        let message = ChatMessage(
            id: nextMessageID(),
            conversationId: conversationID,
            seq: String(conversation.lastSeq),
            senderId: MockSocialSeed.meID,
            clientMessageId: clientMessageID,
            type: .text,
            content: sanitized,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            image: nil,
            deliveryState: .sent
        )
        messages.append(message)
        messagesByConversation[conversationID] = messages
        conversation.updatedAt = message.createdAt
        conversations[conversationID] = conversation
        return message
    }

    func sendImageMessage(
        conversationID: String,
        clientMessageID: String,
        imageData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> ChatMessage {
        try await delay()
        guard var conversation = conversations[conversationID] else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.conversationNotFound"),
                errorCode: SocialErrorCode.conversationNotFound
            )
        }
        guard conversation.imageMessagingEnabled else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.chat.imageDisabled"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }
        guard SocialChatImageSupport.isAllowedContentType(mimeType),
              !imageData.isEmpty,
              imageData.count <= SocialChatImageSupport.maxBytes,
              UIImage(data: imageData) != nil else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.chat.imageInvalid"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }

        let digest = SocialChatImageSupport.sha256Hex(imageData)
        var messages = messagesByConversation[conversationID] ?? []
        if let existing = messages.first(where: {
            $0.clientMessageId == clientMessageID && $0.senderId == MockSocialSeed.meID
        }) {
            if existing.type != .image || imageSHAByClientID[clientMessageID] != digest {
                throw NetworkError.contract(
                    statusCode: 409,
                    message: localizedString("social.error.clientMessageConflict"),
                    errorCode: SocialErrorCode.clientMessageConflict
                )
            }
            return existing.updating(deliveryState: .sent)
        }

        let peer = try requireUser(conversation.peerID)
        guard peer.canMessage else {
            throw NetworkError.contract(
                statusCode: 403,
                message: localizedString("social.error.privacyRestricted"),
                errorCode: SocialErrorCode.privacyRestricted
            )
        }

        conversation.lastSeq += 1
        let messageID = nextMessageID()
        let imageURL = "/api/social/conversations/\(conversationID)/messages/\(messageID)/image"
        let pixel = UIImage(data: imageData)?.size ?? CGSize(width: 1, height: 1)
        let message = ChatMessage(
            id: messageID,
            conversationId: conversationID,
            seq: String(conversation.lastSeq),
            senderId: MockSocialSeed.meID,
            clientMessageId: clientMessageID,
            type: .image,
            content: "",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            image: ChatImageMetadata(
                url: imageURL,
                width: Int(max(pixel.width, 1)),
                height: Int(max(pixel.height, 1)),
                size: imageData.count,
                contentType: mimeType.lowercased()
            ),
            deliveryState: .sent
        )
        messages.append(message)
        messagesByConversation[conversationID] = messages
        imageBytesByMessageID[messageID] = imageData
        imageSHAByClientID[clientMessageID] = digest
        conversation.updatedAt = message.createdAt
        conversations[conversationID] = conversation
        return message
    }

    /// Demo storage is accessible only to the current mock participant, independently of send privacy.
    func imageData(for urlString: String) -> Data? {
        guard let path = SocialChatImageURL.relativePath(
            for: urlString,
            baseURL: URL(string: "https://demo.invalid/api")!
        ) else { return nil }
        let parts = path.split(separator: "/")
        let conversationID = String(parts[2])
        let messageID = String(parts[4])
        guard conversations[conversationID] != nil,
              let message = messagesByConversation[conversationID]?.first(where: { $0.id == messageID }),
              message.type == .image else { return nil }
        return imageBytesByMessageID[messageID]
    }

    private func nextMessageID() -> String {
        String((messagesByConversation.values.flatMap { $0 }.compactMap { Int64($0.id) }.max() ?? 0) + 1)
    }

    func markRead(conversationID: String, lastReadSeq: String) async throws -> ConversationReadState {
        try await delay()
        guard var conversation = conversations[conversationID] else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.conversationNotFound"),
                errorCode: SocialErrorCode.conversationNotFound
            )
        }
        let requested = Int64(lastReadSeq) ?? 0
        let current = Int64(conversation.lastReadSeq) ?? 0
        let capped = min(max(requested, current), conversation.lastSeq)
        conversation.lastReadSeq = String(capped)
        let unread = (messagesByConversation[conversationID] ?? []).filter {
            $0.senderId != MockSocialSeed.meID && $0.seqValue > capped
        }.count
        conversation.unreadCount = unread
        conversations[conversationID] = conversation
        return ConversationReadState(lastReadSeq: conversation.lastReadSeq, unreadCount: unread)
    }

    private func requireUser(_ id: String) throws -> SocialUser {
        guard let user = users[id] else {
            throw NetworkError.contract(
                statusCode: 404,
                message: localizedString("social.error.userNotFound"),
                errorCode: SocialErrorCode.userNotFound
            )
        }
        return user
    }

    private func makeSummary(_ conversation: MutableConversation) -> ConversationSummary {
        let peer = users[conversation.peerID] ?? MockSocialSeed.fallbackPeer(id: conversation.peerID)
        let lastMessage = (messagesByConversation[conversation.id] ?? []).max(by: { $0.seqValue < $1.seqValue })
        return ConversationSummary(
            id: conversation.id,
            peer: peer,
            lastMessage: lastMessage,
            updatedAt: conversation.updatedAt,
            unreadCount: conversation.unreadCount,
            lastReadSeq: conversation.lastReadSeq,
            canSend: peer.canMessage,
            sendPermissionReason: peer.messagePermissionReason,
            imageMessagingEnabled: conversation.imageMessagingEnabled
        )
    }

    private func page<Item: Identifiable & Hashable>(
        _ items: [Item],
        cursor: String?,
        limit: Int
    ) -> SocialPage<Item> where Item.ID == String {
        let safeLimit = min(max(limit, 1), 50)
        let startIndex: Int
        if let cursor, let index = items.firstIndex(where: { $0.id == cursor }) {
            startIndex = items.index(after: index)
        } else {
            startIndex = 0
        }
        guard startIndex < items.count else {
            return SocialPage(items: [], nextCursor: nil, hasMore: false)
        }
        let slice = Array(items[startIndex...].prefix(safeLimit))
        let nextCursor = slice.last?.id
        let endIndex = startIndex + slice.count
        return SocialPage(items: slice, nextCursor: nextCursor, hasMore: endIndex < items.count)
    }

    private func refreshDerivedUserStates() {
        for (id, user) in users {
            let following = follows.contains(FollowEdge(followerID: MockSocialSeed.meID, followeeID: id))
            let followedBy = follows.contains(FollowEdge(followerID: id, followeeID: MockSocialSeed.meID))
            let relationship: SocialRelationship
            if id == MockSocialSeed.meID {
                relationship = .selfRelation
            } else if following && followedBy {
                relationship = .mutual
            } else if following {
                relationship = .following
            } else if followedBy {
                relationship = .followedBy
            } else {
                relationship = .none
            }

            let followingCount = follows.filter { $0.followerID == id }.count
            let followerCount = follows.filter { $0.followeeID == id }.count
            let friendCount = {
                let outgoing = Set(follows.filter { $0.followerID == id }.map(\.followeeID))
                let incoming = Set(follows.filter { $0.followeeID == id }.map(\.followerID))
                return outgoing.intersection(incoming).count
            }()

            let blockedByMe = blocks.contains(id)
            let canMessage: Bool
            let reason: String?
            if id == MockSocialSeed.meID {
                canMessage = false
                reason = nil
            } else if blockedByMe {
                canMessage = false
                reason = SocialErrorCode.contactUnavailable
            } else {
                switch privacy.dmPolicy {
                case .all:
                    canMessage = true
                    reason = nil
                case .following:
                    // FOLLOWING checks receiver(me) -> sender(peer) when peer messages me;
                    // when I message peer, peer's policy is simulated as mutual demo data.
                    canMessage = followedBy || following
                    reason = canMessage ? nil : SocialErrorCode.privacyRestricted
                case .mutual:
                    canMessage = following && followedBy
                    reason = canMessage ? nil : SocialErrorCode.privacyRestricted
                case .none:
                    canMessage = false
                    reason = SocialErrorCode.privacyRestricted
                }
            }

            users[id] = SocialUser(
                id: user.id,
                nickname: user.nickname,
                avatarURL: user.avatarURL,
                introduction: user.introduction,
                followingCount: followingCount,
                followerCount: followerCount,
                friendCount: friendCount,
                relationship: relationship,
                blockedByMe: blockedByMe,
                canMessage: canMessage,
                messagePermissionReason: reason
            )
        }
    }

    private func delay() async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
    }
}

private struct FollowEdge: Hashable {
    let followerID: String
    let followeeID: String
}

private struct MutableConversation {
    let id: String
    let peerID: String
    var updatedAt: String
    var unreadCount: Int
    var lastReadSeq: String
    var lastSeq: Int64
    var imageMessagingEnabled: Bool
}

enum MockSocialSeed {
    static let meID = "user-me-0001"
    static let aliceID = "user-alice-0002"
    static let bobID = "user-bob-0003"
    static let carolID = "user-carol-0004"

    static var users: [SocialUser] {
        [
            SocialUser(
                id: meID,
                nickname: mockLocalizedText(
                    simplifiedChinese: "演示同学",
                    traditionalChinese: "演示同學",
                    english: "Demo Student",
                    japanese: "デモ学生",
                    korean: "데모 학생"
                ),
                avatarURL: nil,
                introduction: mockLocalizedText(
                    simplifiedChinese: "校园助手演示账号",
                    traditionalChinese: "校園助手演示帳號",
                    english: "Campus assistant demo account",
                    japanese: "キャンパス助手のデモアカウント",
                    korean: "캠퍼스 어시스턴트 데모 계정"
                ),
                followingCount: 0,
                followerCount: 0,
                friendCount: 0,
                relationship: .selfRelation,
                blockedByMe: false,
                canMessage: false,
                messagePermissionReason: nil
            ),
            SocialUser(
                id: aliceID,
                nickname: mockLocalizedText(
                    simplifiedChinese: "小林",
                    traditionalChinese: "小林",
                    english: "Alice",
                    japanese: "小林",
                    korean: "샤오린"
                ),
                avatarURL: nil,
                introduction: mockLocalizedText(
                    simplifiedChinese: "喜欢图书馆靠窗的位置",
                    traditionalChinese: "喜歡圖書館靠窗的位置",
                    english: "Loves window seats in the library",
                    japanese: "図書館の窓際が好き",
                    korean: "도서관 창가 자리를 좋아함"
                ),
                followingCount: 0,
                followerCount: 0,
                friendCount: 0,
                relationship: .mutual,
                blockedByMe: false,
                canMessage: true,
                messagePermissionReason: nil
            ),
            SocialUser(
                id: bobID,
                nickname: mockLocalizedText(
                    simplifiedChinese: "阿哲",
                    traditionalChinese: "阿哲",
                    english: "Bob",
                    japanese: "アキラ",
                    korean: "아철"
                ),
                avatarURL: nil,
                introduction: mockLocalizedText(
                    simplifiedChinese: "社团活动组织者",
                    traditionalChinese: "社團活動組織者",
                    english: "Club activity organizer",
                    japanese: "サークル活動の運営",
                    korean: "동아리 활동 운영자"
                ),
                followingCount: 0,
                followerCount: 0,
                friendCount: 0,
                relationship: .followedBy,
                blockedByMe: false,
                canMessage: false,
                messagePermissionReason: SocialErrorCode.privacyRestricted
            ),
            SocialUser(
                id: carolID,
                nickname: mockLocalizedText(
                    simplifiedChinese: "小夏",
                    traditionalChinese: "小夏",
                    english: "Carol",
                    japanese: "ナツ",
                    korean: "샤오샤"
                ),
                avatarURL: nil,
                introduction: mockLocalizedText(
                    simplifiedChinese: "摄影与校园风景",
                    traditionalChinese: "攝影與校園風景",
                    english: "Photography and campus scenery",
                    japanese: "写真とキャンパス風景",
                    korean: "사진과 캠퍼스 풍경"
                ),
                followingCount: 0,
                followerCount: 0,
                friendCount: 0,
                relationship: .following,
                blockedByMe: false,
                canMessage: false,
                messagePermissionReason: SocialErrorCode.privacyRestricted
            )
        ]
    }

    fileprivate static var conversations: [String: MutableConversation] {
        [
            "1": MutableConversation(
                id: "1",
                peerID: aliceID,
                updatedAt: "2026-10-05T12:05:00+08:00",
                unreadCount: 1,
                lastReadSeq: "2",
                lastSeq: 3,
                imageMessagingEnabled: true
            )
        ]
    }

    /// Tiny valid JPEG for mock IMAGE messages (not an empty success stub).
    static var seedJPEGData: Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor(red: 0.18, green: 0.72, blue: 0.42, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }

    static var seedImageBytes: [String: Data] {
        ["3": seedJPEGData]
    }

    static var messages: [String: [ChatMessage]] {
        let jpeg = seedJPEGData
        return [
            "1": [
                ChatMessage(
                    id: "1",
                    conversationId: "1",
                    seq: "1",
                    senderId: meID,
                    clientMessageId: "11111111-1111-1111-1111-111111111111",
                    type: .text,
                    content: mockLocalizedText(
                        simplifiedChinese: "下午图书馆见？",
                        traditionalChinese: "下午圖書館見？",
                        english: "See you at the library this afternoon?",
                        japanese: "午後、図書館で会える？",
                        korean: "오후에 도서관에서 볼까?"
                    ),
                    createdAt: "2026-10-05T11:58:00+08:00",
                    deliveryState: .sent
                ),
                ChatMessage(
                    id: "2",
                    conversationId: "1",
                    seq: "2",
                    senderId: aliceID,
                    clientMessageId: "22222222-2222-2222-2222-222222222222",
                    type: .text,
                    content: mockLocalizedText(
                        simplifiedChinese: "好，三楼靠窗。",
                        traditionalChinese: "好，三樓靠窗。",
                        english: "Sure, third floor by the window.",
                        japanese: "うん、3階の窓際で。",
                        korean: "좋아, 3층 창가에서."
                    ),
                    createdAt: "2026-10-05T12:00:00+08:00",
                    deliveryState: .sent
                ),
                ChatMessage(
                    id: "3",
                    conversationId: "1",
                    seq: "3",
                    senderId: aliceID,
                    clientMessageId: "33333333-3333-3333-3333-333333333333",
                    type: .image,
                    content: "",
                    createdAt: "2026-10-05T12:05:00+08:00",
                    image: ChatImageMetadata(
                        url: "/api/social/conversations/1/messages/3/image",
                        width: 8,
                        height: 8,
                        size: max(jpeg.count, 1),
                        contentType: "image/jpeg"
                    ),
                    deliveryState: .sent
                )
            ]
        ]
    }

    static func fallbackPeer(id: String) -> SocialUser {
        SocialUser(
            id: id,
            nickname: localizedString("social.mapper.defaultNickname"),
            avatarURL: nil,
            introduction: nil,
            followingCount: 0,
            followerCount: 0,
            friendCount: 0,
            relationship: .none,
            blockedByMe: false,
            canMessage: false,
            messagePermissionReason: SocialErrorCode.contactUnavailable
        )
    }
}
