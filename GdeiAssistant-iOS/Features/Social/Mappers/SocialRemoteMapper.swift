import Foundation

enum SocialMappingError: LocalizedError, Equatable {
    case missingRequiredField(String)

    var errorDescription: String? {
        localizedString("social.error.invalidRequest")
    }
}

enum SocialRemoteMapper {
    nonisolated static func mapUser(_ dto: SocialUserRemoteDTO) throws -> SocialUser {
        guard let id = RemoteMapperSupport.sanitizedText(dto.id) else {
            throw SocialMappingError.missingRequiredField("id")
        }

        return SocialUser(
            id: id,
            nickname: RemoteMapperSupport.firstNonEmpty(dto.nickname, localizedString("social.mapper.defaultNickname")),
            avatarURL: RemoteMapperSupport.sanitizedText(dto.avatarUrl),
            introduction: RemoteMapperSupport.sanitizedText(dto.introduction),
            followingCount: max(RemoteMapperSupport.int(dto.followingCount), 0),
            followerCount: max(RemoteMapperSupport.int(dto.followerCount), 0),
            friendCount: max(RemoteMapperSupport.int(dto.friendCount), 0),
            relationship: SocialRelationship.resolved(dto.relationship),
            blockedByMe: dto.blockedByMe ?? false,
            canMessage: dto.canMessage ?? false,
            messagePermissionReason: RemoteMapperSupport.sanitizedText(dto.messagePermissionReason)
        )
    }

    nonisolated static func mapUsers(_ dtos: [SocialUserRemoteDTO]) -> [SocialUser] {
        dtos.compactMap { try? mapUser($0) }
    }

    nonisolated static func mapUserPage(_ dto: SocialPageRemoteDTO<SocialUserRemoteDTO>) -> SocialPage<SocialUser> {
        SocialPage(
            items: mapUsers(dto.items ?? []),
            nextCursor: RemoteMapperSupport.sanitizedText(dto.nextCursor),
            hasMore: dto.hasMore ?? false
        )
    }

    nonisolated static func mapMessage(
        _ dto: ChatMessageRemoteDTO,
        deliveryState: ChatDeliveryState = .sent
    ) throws -> ChatMessage {
        guard let id = RemoteMapperSupport.sanitizedText(dto.id) else {
            throw SocialMappingError.missingRequiredField("id")
        }
        guard let conversationId = RemoteMapperSupport.sanitizedText(dto.conversationId) else {
            throw SocialMappingError.missingRequiredField("conversationId")
        }
        guard let seq = RemoteMapperSupport.sanitizedText(dto.seq?.rawValue), Int64(seq) != nil else {
            throw SocialMappingError.missingRequiredField("seq")
        }
        guard let senderId = RemoteMapperSupport.sanitizedText(dto.senderId) else {
            throw SocialMappingError.missingRequiredField("senderId")
        }
        guard let clientMessageId = RemoteMapperSupport.sanitizedText(dto.clientMessageId) else {
            throw SocialMappingError.missingRequiredField("clientMessageId")
        }
        guard let createdAt = RemoteMapperSupport.sanitizedText(dto.createdAt) else {
            throw SocialMappingError.missingRequiredField("createdAt")
        }

        let type = ChatMessageType.resolved(dto.type)
        let image: ChatImageMetadata?
        let content: String
        switch type {
        case .image:
            image = try mapImageMetadata(dto.image)
            // IMAGE body is empty; do not invent placeholder text.
            content = ""
        case .text:
            guard let text = RemoteMapperSupport.sanitizedText(dto.content) else {
                throw SocialMappingError.missingRequiredField("content")
            }
            image = nil
            content = text
        }

        return ChatMessage(
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

    nonisolated static func mapImageMetadata(_ dto: ChatImageRemoteDTO?) throws -> ChatImageMetadata {
        guard let dto else {
            throw SocialMappingError.missingRequiredField("image")
        }
        guard let url = RemoteMapperSupport.sanitizedText(dto.url) else {
            throw SocialMappingError.missingRequiredField("image.url")
        }
        guard SocialChatImageSupport.isAllowedContentType(dto.contentType),
              let contentType = RemoteMapperSupport.sanitizedText(dto.contentType)?.lowercased() else {
            throw SocialMappingError.missingRequiredField("image.contentType")
        }
        let width = RemoteMapperSupport.int(dto.width)
        let height = RemoteMapperSupport.int(dto.height)
        let size = RemoteMapperSupport.int(dto.size)
        guard width > 0, height > 0, width <= 4096, height <= 4096,
              width * height <= 16_000_000, size > 0, size <= SocialChatImageSupport.maxBytes else {
            throw SocialMappingError.missingRequiredField("image.dimensions")
        }
        return ChatImageMetadata(
            url: url,
            width: width,
            height: height,
            size: size,
            contentType: contentType
        )
    }

    nonisolated static func mapMessages(_ dtos: [ChatMessageRemoteDTO]) -> [ChatMessage] {
        dtos.compactMap { try? mapMessage($0) }
    }

    nonisolated static func mapMessagePage(
        _ dto: SocialPageRemoteDTO<ChatMessageRemoteDTO>
    ) -> SocialPage<ChatMessage> {
        SocialPage(
            items: mapMessages(dto.items ?? []),
            nextCursor: RemoteMapperSupport.sanitizedText(dto.nextCursor),
            hasMore: dto.hasMore ?? false
        )
    }

    nonisolated static func mapConversation(_ dto: ConversationRemoteDTO) throws -> ConversationSummary {
        guard let id = RemoteMapperSupport.sanitizedText(dto.id) else {
            throw SocialMappingError.missingRequiredField("id")
        }
        guard let peerDTO = dto.peer else {
            throw SocialMappingError.missingRequiredField("peer")
        }
        let peer = try mapUser(peerDTO)
        guard let updatedAt = RemoteMapperSupport.sanitizedText(dto.updatedAt) else {
            throw SocialMappingError.missingRequiredField("updatedAt")
        }
        guard let lastReadSeq = RemoteMapperSupport.sanitizedText(dto.lastReadSeq?.rawValue), Int64(lastReadSeq) != nil else {
            throw SocialMappingError.missingRequiredField("lastReadSeq")
        }

        let lastMessage: ChatMessage?
        if let lastMessageDTO = dto.lastMessage {
            // Nested summary message is optional; drop malformed items instead of inventing fields.
            lastMessage = try? mapMessage(lastMessageDTO)
        } else {
            lastMessage = nil
        }

        return ConversationSummary(
            id: id,
            peer: peer,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            unreadCount: max(RemoteMapperSupport.int(dto.unreadCount), 0),
            lastReadSeq: lastReadSeq,
            canSend: dto.canSend ?? false,
            sendPermissionReason: RemoteMapperSupport.sanitizedText(dto.sendPermissionReason),
            imageMessagingEnabled: dto.imageMessagingEnabled ?? false
        )
    }

    nonisolated static func mapConversations(_ dtos: [ConversationRemoteDTO]) -> [ConversationSummary] {
        dtos.compactMap { try? mapConversation($0) }
    }

    nonisolated static func mapConversationPage(
        _ dto: SocialPageRemoteDTO<ConversationRemoteDTO>
    ) -> SocialPage<ConversationSummary> {
        SocialPage(
            items: mapConversations(dto.items ?? []),
            nextCursor: RemoteMapperSupport.sanitizedText(dto.nextCursor),
            hasMore: dto.hasMore ?? false
        )
    }

    nonisolated static func mapPrivacy(_ dto: DirectMessagePrivacyRemoteDTO) -> DirectMessagePrivacy {
        DirectMessagePrivacy(dmPolicy: DirectMessagePolicy.resolved(dto.dmPolicy))
    }

    nonisolated static func mapUnread(_ dto: SocialUnreadRemoteDTO) -> SocialUnreadCount {
        SocialUnreadCount(total: max(RemoteMapperSupport.int(dto.total), 0))
    }

    nonisolated static func mapBlockState(_ dto: SocialBlockStateRemoteDTO) throws -> SocialBlockState {
        guard let blocked = dto.blocked else {
            throw SocialMappingError.missingRequiredField("blocked")
        }
        return SocialBlockState(blocked: blocked)
    }

    nonisolated static func mapReadState(_ dto: ConversationReadStateRemoteDTO) throws -> ConversationReadState {
        guard let lastReadSeq = RemoteMapperSupport.sanitizedText(dto.lastReadSeq?.rawValue), Int64(lastReadSeq) != nil else {
            throw SocialMappingError.missingRequiredField("lastReadSeq")
        }
        guard dto.unreadCount != nil else {
            throw SocialMappingError.missingRequiredField("unreadCount")
        }
        return ConversationReadState(
            lastReadSeq: lastReadSeq,
            unreadCount: max(RemoteMapperSupport.int(dto.unreadCount), 0)
        )
    }

    /// Length uses Unicode scalar / code point count to match Java `codePointCount` and Android.
    nonisolated static func sanitizedMessageContent(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.unicodeScalars.count <= 1000 else { return nil }
        return trimmed
    }

    nonisolated static func mappingFailure(_ error: SocialMappingError) -> NetworkError {
        NetworkError.decoding(error)
    }
}
