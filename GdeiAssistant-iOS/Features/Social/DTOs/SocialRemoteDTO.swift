import Foundation

nonisolated struct SocialUserRemoteDTO: Decodable {
    let id: String?
    let nickname: String?
    let avatarUrl: String?
    let introduction: String?
    let followingCount: RemoteFlexibleString?
    let followerCount: RemoteFlexibleString?
    let friendCount: RemoteFlexibleString?
    let relationship: String?
    let blockedByMe: Bool?
    let canMessage: Bool?
    let messagePermissionReason: String?
}

nonisolated struct SocialPageRemoteDTO<Item: Decodable>: Decodable {
    let items: [Item]?
    let nextCursor: String?
    let hasMore: Bool?
}

nonisolated struct ChatImageRemoteDTO: Decodable {
    let url: String?
    let width: RemoteFlexibleString?
    let height: RemoteFlexibleString?
    let size: RemoteFlexibleString?
    let contentType: String?
}

nonisolated struct ChatMessageRemoteDTO: Decodable {
    let id: String?
    let conversationId: String?
    let seq: RemoteFlexibleString?
    let senderId: String?
    let clientMessageId: String?
    let type: String?
    let content: String?
    let createdAt: String?
    let image: ChatImageRemoteDTO?
}

nonisolated struct ConversationRemoteDTO: Decodable {
    let id: String?
    let peer: SocialUserRemoteDTO?
    let lastMessage: ChatMessageRemoteDTO?
    let updatedAt: String?
    let unreadCount: RemoteFlexibleString?
    let lastReadSeq: RemoteFlexibleString?
    let canSend: Bool?
    let sendPermissionReason: String?
    let imageMessagingEnabled: Bool?
}

nonisolated struct DirectMessagePrivacyRemoteDTO: Decodable {
    let dmPolicy: String?
}

nonisolated struct SocialUnreadRemoteDTO: Decodable {
    let total: RemoteFlexibleString?
}

nonisolated struct SocialBlockStateRemoteDTO: Decodable {
    let blocked: Bool?
}

nonisolated struct ConversationReadStateRemoteDTO: Decodable {
    let lastReadSeq: RemoteFlexibleString?
    let unreadCount: RemoteFlexibleString?
}

nonisolated struct SocialRealtimeEnvelopeDTO: Decodable {
    let type: String?
    let conversationId: String?
    let messageId: String?
    let seq: RemoteFlexibleString?
    let readerId: String?
    let lastReadSeq: RemoteFlexibleString?
    let token: String?
}
