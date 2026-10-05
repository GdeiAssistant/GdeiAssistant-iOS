import Foundation

@MainActor
protocol SocialRepository {
    func fetchMe() async throws -> SocialUser
    func searchUsers(query: String, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser>
    func fetchUser(id: String) async throws -> SocialUser
    func fetchRelationships(
        userID: String,
        kind: SocialRelationshipKind,
        cursor: String?,
        limit: Int
    ) async throws -> SocialPage<SocialUser>
    func follow(userID: String) async throws -> SocialUser
    func unfollow(userID: String) async throws -> SocialUser
    func block(userID: String) async throws -> SocialBlockState
    func unblock(userID: String) async throws -> SocialBlockState
    func fetchBlocks(cursor: String?, limit: Int) async throws -> SocialPage<SocialUser>
    func fetchPrivacy() async throws -> DirectMessagePrivacy
    func updatePrivacy(_ policy: DirectMessagePolicy) async throws -> DirectMessagePrivacy
    func fetchUnreadCount() async throws -> SocialUnreadCount
    func createConversation(peerID: String) async throws -> ConversationSummary
    func fetchConversations(cursor: String?, limit: Int) async throws -> SocialPage<ConversationSummary>
    func fetchConversation(id: String) async throws -> ConversationSummary
    func fetchMessages(
        conversationID: String,
        beforeSeq: String?,
        afterSeq: String?,
        limit: Int
    ) async throws -> SocialPage<ChatMessage>
    func sendMessage(
        conversationID: String,
        clientMessageID: String,
        content: String
    ) async throws -> ChatMessage
    func sendImageMessage(
        conversationID: String,
        clientMessageID: String,
        imageData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> ChatMessage
    func markRead(conversationID: String, lastReadSeq: String) async throws -> ConversationReadState
}

@MainActor
final class SwitchingSocialRepository: SocialRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any SocialRepository
    private let mockRepository: any SocialRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any SocialRepository,
        mockRepository: any SocialRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchMe() async throws -> SocialUser {
        try await currentRepository.fetchMe()
    }

    func searchUsers(query: String, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await currentRepository.searchUsers(query: query, cursor: cursor, limit: limit)
    }

    func fetchUser(id: String) async throws -> SocialUser {
        try await currentRepository.fetchUser(id: id)
    }

    func fetchRelationships(
        userID: String,
        kind: SocialRelationshipKind,
        cursor: String?,
        limit: Int
    ) async throws -> SocialPage<SocialUser> {
        try await currentRepository.fetchRelationships(userID: userID, kind: kind, cursor: cursor, limit: limit)
    }

    func follow(userID: String) async throws -> SocialUser {
        try await currentRepository.follow(userID: userID)
    }

    func unfollow(userID: String) async throws -> SocialUser {
        try await currentRepository.unfollow(userID: userID)
    }

    func block(userID: String) async throws -> SocialBlockState {
        try await currentRepository.block(userID: userID)
    }

    func unblock(userID: String) async throws -> SocialBlockState {
        try await currentRepository.unblock(userID: userID)
    }

    func fetchBlocks(cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await currentRepository.fetchBlocks(cursor: cursor, limit: limit)
    }

    func fetchPrivacy() async throws -> DirectMessagePrivacy {
        try await currentRepository.fetchPrivacy()
    }

    func updatePrivacy(_ policy: DirectMessagePolicy) async throws -> DirectMessagePrivacy {
        try await currentRepository.updatePrivacy(policy)
    }

    func fetchUnreadCount() async throws -> SocialUnreadCount {
        try await currentRepository.fetchUnreadCount()
    }

    func createConversation(peerID: String) async throws -> ConversationSummary {
        try await currentRepository.createConversation(peerID: peerID)
    }

    func fetchConversations(cursor: String?, limit: Int) async throws -> SocialPage<ConversationSummary> {
        try await currentRepository.fetchConversations(cursor: cursor, limit: limit)
    }

    func fetchConversation(id: String) async throws -> ConversationSummary {
        try await currentRepository.fetchConversation(id: id)
    }

    func fetchMessages(
        conversationID: String,
        beforeSeq: String?,
        afterSeq: String?,
        limit: Int
    ) async throws -> SocialPage<ChatMessage> {
        try await currentRepository.fetchMessages(
            conversationID: conversationID,
            beforeSeq: beforeSeq,
            afterSeq: afterSeq,
            limit: limit
        )
    }

    func sendMessage(
        conversationID: String,
        clientMessageID: String,
        content: String
    ) async throws -> ChatMessage {
        try await currentRepository.sendMessage(
            conversationID: conversationID,
            clientMessageID: clientMessageID,
            content: content
        )
    }

    func sendImageMessage(
        conversationID: String,
        clientMessageID: String,
        imageData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> ChatMessage {
        try await currentRepository.sendImageMessage(
            conversationID: conversationID,
            clientMessageID: clientMessageID,
            imageData: imageData,
            fileName: fileName,
            mimeType: mimeType
        )
    }

    func markRead(conversationID: String, lastReadSeq: String) async throws -> ConversationReadState {
        try await currentRepository.markRead(conversationID: conversationID, lastReadSeq: lastReadSeq)
    }

    /// Local demo bytes; remote mode never falls back to mock private media.
    func demoImageData(for urlString: String) -> Data? {
        guard environment.dataSourceMode == .mock else { return nil }
        return (mockRepository as? MockSocialRepository)?.imageData(for: urlString)
    }

    private var currentRepository: any SocialRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
