import Foundation
import UIKit

@MainActor
final class RemoteSocialRepository: SocialRepository {
    private let apiClient: APIClient
    private let pathPrefix = "/social"

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchMe() async throws -> SocialUser {
        let dto: SocialUserRemoteDTO = try await apiClient.get("\(pathPrefix)/me")
        return try mapRequired(SocialRemoteMapper.mapUser(dto))
    }

    func searchUsers(query: String, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        let dto: SocialPageRemoteDTO<SocialUserRemoteDTO> = try await apiClient.get(
            "\(pathPrefix)/users",
            queryItems: pageQueryItems(query: query, cursor: cursor, limit: limit)
        )
        return SocialRemoteMapper.mapUserPage(dto)
    }

    func fetchUser(id: String) async throws -> SocialUser {
        let dto: SocialUserRemoteDTO = try await apiClient.get("\(pathPrefix)/users/\(id)")
        return try mapRequired(SocialRemoteMapper.mapUser(dto))
    }

    func fetchRelationships(
        userID: String,
        kind: SocialRelationshipKind,
        cursor: String?,
        limit: Int
    ) async throws -> SocialPage<SocialUser> {
        var items = pageQueryItems(cursor: cursor, limit: limit)
        items.append(URLQueryItem(name: "kind", value: kind.rawValue))
        let dto: SocialPageRemoteDTO<SocialUserRemoteDTO> = try await apiClient.get(
            "\(pathPrefix)/users/\(userID)/relationships",
            queryItems: items
        )
        return SocialRemoteMapper.mapUserPage(dto)
    }

    func follow(userID: String) async throws -> SocialUser {
        let dto: SocialUserRemoteDTO = try await apiClient.put("\(pathPrefix)/users/\(userID)/follow")
        return try mapRequired(SocialRemoteMapper.mapUser(dto))
    }

    func unfollow(userID: String) async throws -> SocialUser {
        let dto: SocialUserRemoteDTO = try await apiClient.delete("\(pathPrefix)/users/\(userID)/follow")
        return try mapRequired(SocialRemoteMapper.mapUser(dto))
    }

    func block(userID: String) async throws -> SocialBlockState {
        let dto: SocialBlockStateRemoteDTO = try await apiClient.put("\(pathPrefix)/users/\(userID)/block")
        return try mapRequired(SocialRemoteMapper.mapBlockState(dto))
    }

    func unblock(userID: String) async throws -> SocialBlockState {
        let dto: SocialBlockStateRemoteDTO = try await apiClient.delete("\(pathPrefix)/users/\(userID)/block")
        return try mapRequired(SocialRemoteMapper.mapBlockState(dto))
    }

    func fetchBlocks(cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        let dto: SocialPageRemoteDTO<SocialUserRemoteDTO> = try await apiClient.get(
            "\(pathPrefix)/blocks",
            queryItems: pageQueryItems(cursor: cursor, limit: limit)
        )
        return SocialRemoteMapper.mapUserPage(dto)
    }

    func fetchPrivacy() async throws -> DirectMessagePrivacy {
        let dto: DirectMessagePrivacyRemoteDTO = try await apiClient.get("\(pathPrefix)/privacy")
        return SocialRemoteMapper.mapPrivacy(dto)
    }

    func updatePrivacy(_ policy: DirectMessagePolicy) async throws -> DirectMessagePrivacy {
        let dto: DirectMessagePrivacyRemoteDTO = try await apiClient.put(
            "\(pathPrefix)/privacy",
            body: UpdateDirectMessagePrivacyRequest(dmPolicy: policy.rawValue)
        )
        return SocialRemoteMapper.mapPrivacy(dto)
    }

    func fetchUnreadCount() async throws -> SocialUnreadCount {
        let dto: SocialUnreadRemoteDTO = try await apiClient.get("\(pathPrefix)/unread")
        return SocialRemoteMapper.mapUnread(dto)
    }

    func createConversation(peerID: String) async throws -> ConversationSummary {
        let dto: ConversationRemoteDTO = try await apiClient.post(
            "\(pathPrefix)/conversations",
            body: CreateConversationRequest(peerId: peerID)
        )
        return try mapRequired(SocialRemoteMapper.mapConversation(dto))
    }

    func fetchConversations(cursor: String?, limit: Int) async throws -> SocialPage<ConversationSummary> {
        let dto: SocialPageRemoteDTO<ConversationRemoteDTO> = try await apiClient.get(
            "\(pathPrefix)/conversations",
            queryItems: pageQueryItems(cursor: cursor, limit: limit)
        )
        return SocialRemoteMapper.mapConversationPage(dto)
    }

    func fetchConversation(id: String) async throws -> ConversationSummary {
        let dto: ConversationRemoteDTO = try await apiClient.get("\(pathPrefix)/conversations/\(id)")
        return try mapRequired(SocialRemoteMapper.mapConversation(dto))
    }

    func fetchMessages(
        conversationID: String,
        beforeSeq: String?,
        afterSeq: String?,
        limit: Int
    ) async throws -> SocialPage<ChatMessage> {
        var items = [URLQueryItem(name: "limit", value: String(clampedLimit(limit)))]
        if let beforeSeq, !beforeSeq.isEmpty {
            items.append(URLQueryItem(name: "beforeSeq", value: beforeSeq))
        } else if let afterSeq, !afterSeq.isEmpty {
            items.append(URLQueryItem(name: "afterSeq", value: afterSeq))
        }
        let dto: SocialPageRemoteDTO<ChatMessageRemoteDTO> = try await apiClient.get(
            "\(pathPrefix)/conversations/\(conversationID)/messages",
            queryItems: items
        )
        return SocialRemoteMapper.mapMessagePage(dto)
    }

    func sendMessage(
        conversationID: String,
        clientMessageID: String,
        content: String
    ) async throws -> ChatMessage {
        guard let sanitized = SocialRemoteMapper.sanitizedMessageContent(content) else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.error.invalidRequest"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }
        let dto: ChatMessageRemoteDTO = try await apiClient.post(
            "\(pathPrefix)/conversations/\(conversationID)/messages",
            body: SendChatMessageRequest(clientMessageId: clientMessageID, content: sanitized)
        )
        return try mapRequired(SocialRemoteMapper.mapMessage(dto, deliveryState: .sent))
    }

    func sendImageMessage(
        conversationID: String,
        clientMessageID: String,
        imageData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> ChatMessage {
        guard SocialChatImageSupport.isAllowedContentType(mimeType),
              !imageData.isEmpty,
              imageData.count <= SocialChatImageSupport.maxBytes,
              UIImage(data: imageData) != nil else {
            throw NetworkError.contract(
                statusCode: 400,
                message: localizedString("social.error.invalidRequest"),
                errorCode: SocialErrorCode.invalidRequest
            )
        }
        // Client path converts to JPEG via UploadImageAsset; MultipartFormDataBuilder runs in postMultipart.
        let asset = UploadImageAsset(
            fileName: fileName,
            mimeType: mimeType.lowercased(),
            data: imageData
        )
        let file = MultipartFormFile(
            name: "image",
            fileName: asset.fileName,
            mimeType: asset.mimeType,
            data: asset.data
        )
        let dto: ChatMessageRemoteDTO = try await apiClient.postMultipart(
            "\(pathPrefix)/conversations/\(conversationID)/messages/image",
            fields: [FormFieldValue(name: "clientMessageId", value: clientMessageID)],
            files: [file],
            requiresAuth: true
        )
        return try mapRequired(SocialRemoteMapper.mapMessage(dto, deliveryState: .sent))
    }

    func markRead(conversationID: String, lastReadSeq: String) async throws -> ConversationReadState {
        let dto: ConversationReadStateRemoteDTO = try await apiClient.put(
            "\(pathPrefix)/conversations/\(conversationID)/read",
            body: MarkConversationReadRequest(lastReadSeq: lastReadSeq)
        )
        return try mapRequired(SocialRemoteMapper.mapReadState(dto))
    }

    private func mapRequired<T>(_ mapper: @autoclosure () throws -> T) throws -> T {
        do {
            return try mapper()
        } catch let error as SocialMappingError {
            throw SocialRemoteMapper.mappingFailure(error)
        }
    }

    private func pageQueryItems(
        query: String? = nil,
        cursor: String? = nil,
        limit: Int
    ) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(clampedLimit(limit)))]
        if let query {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append(URLQueryItem(name: "query", value: trimmed))
            }
        }
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return items
    }

    private func clampedLimit(_ limit: Int) -> Int {
        min(max(limit, 1), 50)
    }
}
