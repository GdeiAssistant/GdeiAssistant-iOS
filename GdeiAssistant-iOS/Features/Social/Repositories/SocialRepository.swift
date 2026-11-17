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
