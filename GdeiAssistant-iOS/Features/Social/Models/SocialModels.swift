import Foundation

enum SocialRelationship: String, Codable, Hashable, CaseIterable {
    case selfRelation = "SELF"
    case none = "NONE"
    case following = "FOLLOWING"
    case followedBy = "FOLLOWED_BY"
    case mutual = "MUTUAL"

    nonisolated static func resolved(_ rawValue: String?) -> SocialRelationship {
        switch (rawValue ?? "").uppercased() {
        case "SELF":
            return .selfRelation
        case "FOLLOWING":
            return .following
        case "FOLLOWED_BY":
            return .followedBy
        case "MUTUAL":
            return .mutual
        default:
            return .none
        }
    }
}

enum SocialRelationshipKind: String, Codable, Hashable, CaseIterable, Identifiable {
    case following
    case followers
    case friends

    var id: String { rawValue }

    var title: String {
        switch self {
        case .following:
            return localizedString("social.relationship.following")
        case .followers:
            return localizedString("social.relationship.followers")
        case .friends:
            return localizedString("social.relationship.friends")
        }
    }
}

enum DirectMessagePolicy: String, Codable, Hashable, CaseIterable, Identifiable {
    case all = "ALL"
    case following = "FOLLOWING"
    case mutual = "MUTUAL"
    case none = "NONE"

    var id: String { rawValue }

    /// Unknown or missing values must not become ALL.
    nonisolated static func resolved(_ rawValue: String?) -> DirectMessagePolicy {
        guard let rawValue else { return .mutual }
        switch rawValue.uppercased() {
        case "ALL":
            return .all
        case "FOLLOWING":
            return .following
        case "NONE":
            return .none
        case "MUTUAL":
            return .mutual
        default:
            return .mutual
        }
    }

    var title: String {
        switch self {
        case .all:
            return localizedString("social.dmPolicy.all")
        case .following:
            return localizedString("social.dmPolicy.following")
        case .mutual:
            return localizedString("social.dmPolicy.mutual")
        case .none:
            return localizedString("social.dmPolicy.none")
        }
    }

    var subtitle: String {
        switch self {
        case .all:
            return localizedString("social.dmPolicy.all.hint")
        case .following:
            return localizedString("social.dmPolicy.following.hint")
        case .mutual:
            return localizedString("social.dmPolicy.mutual.hint")
        case .none:
            return localizedString("social.dmPolicy.none.hint")
        }
    }
}

enum ChatDeliveryState: String, Codable, Hashable {
    case pending
    case sent
    case failed
}

enum ChatMessageType: String, Codable, Hashable {
    case text = "TEXT"
    case image = "IMAGE"

    /// Legacy payloads without `type` are TEXT.
    nonisolated static func resolved(_ rawValue: String?) -> ChatMessageType {
        switch (rawValue ?? "").uppercased() {
        case "IMAGE":
            return .image
        default:
            return .text
        }
    }
}

nonisolated struct ChatImageMetadata: Codable, Hashable {
    let url: String
    let width: Int
    let height: Int
    let size: Int
    let contentType: String
}

nonisolated struct SocialUser: Codable, Identifiable, Hashable {
    let id: String
    let nickname: String
    let avatarURL: String?
    let introduction: String?
    let followingCount: Int
    let followerCount: Int
    let friendCount: Int
    let relationship: SocialRelationship
    let blockedByMe: Bool
    let canMessage: Bool
    let messagePermissionReason: String?

    var isSelf: Bool {
        relationship == .selfRelation
    }

    var isFollowing: Bool {
        relationship == .following || relationship == .mutual
    }

    var relationshipBadgeText: String {
        switch relationship {
        case .selfRelation:
            return localizedString("social.relationship.self")
        case .none:
            return localizedString("social.relationship.none")
        case .following:
            return localizedString("social.relationship.following")
        case .followedBy:
            return localizedString("social.relationship.followedBy")
        case .mutual:
            return localizedString("social.relationship.friends")
        }
    }
}

nonisolated struct SocialPage<Item: Codable & Hashable>: Codable, Hashable {
    let items: [Item]
    let nextCursor: String?
    let hasMore: Bool
}

nonisolated struct ChatMessage: Codable, Identifiable, Hashable {
    let id: String
    let conversationId: String
    let seq: String
    let senderId: String
    let clientMessageId: String
    let type: ChatMessageType
    let content: String
    let createdAt: String
    let image: ChatImageMetadata?
    let deliveryState: ChatDeliveryState

    nonisolated init(
        id: String,
        conversationId: String,
        seq: String,
        senderId: String,
        clientMessageId: String,
        type: ChatMessageType = .text,
        content: String,
        createdAt: String,
        image: ChatImageMetadata? = nil,
        deliveryState: ChatDeliveryState
    ) {
        self.id = id
        self.conversationId = conversationId
        self.seq = seq
        self.senderId = senderId
        self.clientMessageId = clientMessageId
        self.type = type
        self.content = content
        self.createdAt = createdAt
        self.image = image
        self.deliveryState = deliveryState
    }

    var seqValue: Int64 {
        Int64(seq) ?? 0
    }

    /// Inbox / list preview; IMAGE uses localized summary, never empty success text.
    var previewText: String {
        switch type {
        case .image:
            return localizedString("social.chat.imageSummary")
        case .text:
            return content
        }
    }

    nonisolated func updating(deliveryState: ChatDeliveryState) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationId: conversationId,
            seq: seq,
            senderId: senderId,
            clientMessageId: clientMessageId,
            type: type,
            content: content,
            createdAt: createdAt,
            image: image,
            deliveryState: deliveryState
        )
    }

    func merging(server: ChatMessage) -> ChatMessage {
        ChatMessage(
            id: server.id,
            conversationId: server.conversationId,
            seq: server.seq,
            senderId: server.senderId,
            clientMessageId: server.clientMessageId,
            type: server.type,
            content: server.content,
            createdAt: server.createdAt,
            image: server.image,
            deliveryState: .sent
        )
    }
}

nonisolated struct ConversationSummary: Codable, Identifiable, Hashable {
    let id: String
    let peer: SocialUser
    let lastMessage: ChatMessage?
    let updatedAt: String
    let unreadCount: Int
    let lastReadSeq: String
    let canSend: Bool
    let sendPermissionReason: String?
    /// Server image storage readiness; missing defaults to false.
    let imageMessagingEnabled: Bool

    init(
        id: String,
        peer: SocialUser,
        lastMessage: ChatMessage?,
        updatedAt: String,
        unreadCount: Int,
        lastReadSeq: String,
        canSend: Bool,
        sendPermissionReason: String?,
        imageMessagingEnabled: Bool = false
    ) {
        self.id = id
        self.peer = peer
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        self.lastReadSeq = lastReadSeq
        self.canSend = canSend
        self.sendPermissionReason = sendPermissionReason
        self.imageMessagingEnabled = imageMessagingEnabled
    }
}

struct DirectMessagePrivacy: Codable, Hashable {
    let dmPolicy: DirectMessagePolicy
}

struct SocialUnreadCount: Codable, Hashable {
    let total: Int
}

struct SocialBlockState: Codable, Hashable {
    let blocked: Bool
}

struct ConversationReadState: Codable, Hashable {
    let lastReadSeq: String
    let unreadCount: Int
}

struct CreateConversationRequest: Encodable {
    let peerId: String
}

struct SendChatMessageRequest: Encodable {
    let clientMessageId: String
    let content: String
}

struct MarkConversationReadRequest: Encodable {
    let lastReadSeq: String
}

struct UpdateDirectMessagePrivacyRequest: Encodable {
    let dmPolicy: String
}
