import XCTest
@testable import GdeiAssistant_iOS

final class SocialRemoteMapperTests: XCTestCase {
    func testMapUserResolvesRelationshipWithoutInventingIdentity() throws {
        let dto = SocialUserRemoteDTO(
            id: " user-1 ",
            nickname: " 小林 ",
            avatarUrl: " /api/social/users/user-1/avatar ",
            introduction: " intro ",
            followingCount: RemoteFlexibleString("3"),
            followerCount: RemoteFlexibleString("5"),
            friendCount: RemoteFlexibleString("2"),
            relationship: "mutual",
            blockedByMe: false,
            canMessage: true,
            messagePermissionReason: nil
        )

        let user = try SocialRemoteMapper.mapUser(dto)
        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.nickname, "小林")
        XCTAssertEqual(user.avatarURL, "/api/social/users/user-1/avatar")
        XCTAssertEqual(user.followingCount, 3)
        XCTAssertEqual(user.followerCount, 5)
        XCTAssertEqual(user.friendCount, 2)
        XCTAssertEqual(user.relationship, .mutual)
        XCTAssertTrue(user.canMessage)
    }

    func testMapUserRejectsMissingId() {
        let dto = SocialUserRemoteDTO(
            id: "  ",
            nickname: "小林",
            avatarUrl: nil,
            introduction: nil,
            followingCount: nil,
            followerCount: nil,
            friendCount: nil,
            relationship: "NONE",
            blockedByMe: false,
            canMessage: false,
            messagePermissionReason: nil
        )

        XCTAssertThrowsError(try SocialRemoteMapper.mapUser(dto)) { error in
            XCTAssertEqual(error as? SocialMappingError, .missingRequiredField("id"))
        }
    }

    func testMapMessageRejectsMissingCriticalFields() {
        let missingID = ChatMessageRemoteDTO(
            id: nil,
            conversationId: "c1",
            seq: RemoteFlexibleString("1"),
            senderId: "a",
            clientMessageId: "cid-1",
            type: nil,
            content: "hi",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: nil
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapMessage(missingID))

        let missingClientMessageID = ChatMessageRemoteDTO(
            id: "1",
            conversationId: "c1",
            seq: RemoteFlexibleString("1"),
            senderId: "a",
            clientMessageId: " ",
            type: nil,
            content: "hi",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: nil
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapMessage(missingClientMessageID)) { error in
            XCTAssertEqual(error as? SocialMappingError, .missingRequiredField("clientMessageId"))
        }

        let missingCreatedAt = ChatMessageRemoteDTO(
            id: "1",
            conversationId: "c1",
            seq: RemoteFlexibleString("1"),
            senderId: "a",
            clientMessageId: "cid-1",
            type: nil,
            content: "hi",
            createdAt: nil,
            image: nil
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapMessage(missingCreatedAt)) { error in
            XCTAssertEqual(error as? SocialMappingError, .missingRequiredField("createdAt"))
        }
    }

    func testMapMessageDefaultsMissingTypeToText() throws {
        let dto = ChatMessageRemoteDTO(
            id: "1",
            conversationId: "c1",
            seq: RemoteFlexibleString("3"),
            senderId: "a",
            clientMessageId: "cid-1",
            type: nil,
            content: "hello",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: nil
        )
        let message = try SocialRemoteMapper.mapMessage(dto)
        XCTAssertEqual(message.type, .text)
        XCTAssertEqual(message.content, "hello")
        XCTAssertNil(message.image)
    }

    func testMapImageMessageRequiresStrictMetadata() throws {
        let good = ChatMessageRemoteDTO(
            id: "img-1",
            conversationId: "c1",
            seq: RemoteFlexibleString("9"),
            senderId: "a",
            clientMessageId: "cid-img",
            type: "IMAGE",
            content: "",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: ChatImageRemoteDTO(
                url: "/api/social/conversations/c1/messages/img-1/image",
                width: RemoteFlexibleString("640"),
                height: RemoteFlexibleString("480"),
                size: RemoteFlexibleString("1200"),
                contentType: "image/jpeg"
            )
        )
        let mapped = try SocialRemoteMapper.mapMessage(good)
        XCTAssertEqual(mapped.type, .image)
        XCTAssertEqual(mapped.content, "")
        XCTAssertEqual(mapped.image?.contentType, "image/jpeg")
        XCTAssertEqual(mapped.previewText, localizedString("social.chat.imageSummary"))

        let missingImage = ChatMessageRemoteDTO(
            id: "img-2",
            conversationId: "c1",
            seq: RemoteFlexibleString("10"),
            senderId: "a",
            clientMessageId: "cid-img-2",
            type: "IMAGE",
            content: "",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: nil
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapMessage(missingImage))

        let badType = ChatMessageRemoteDTO(
            id: "img-3",
            conversationId: "c1",
            seq: RemoteFlexibleString("11"),
            senderId: "a",
            clientMessageId: "cid-img-3",
            type: "IMAGE",
            content: "",
            createdAt: "2026-10-05T10:00:00+08:00",
            image: ChatImageRemoteDTO(
                url: "/api/social/conversations/c1/messages/img-3/image",
                width: RemoteFlexibleString("10"),
                height: RemoteFlexibleString("10"),
                size: RemoteFlexibleString("100"),
                contentType: "image/gif"
            )
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapMessage(badType))
    }

    func testImageMetadataRejectsExcessiveDimensionsAndSize() {
        for (width, height, size) in [(0, 10, 100), (4097, 10, 100), (4096, 4096, 100),
                                      (10, 10, SocialChatImageSupport.maxBytes + 1)] {
            let dto = ChatImageRemoteDTO(
                url: "/api/social/conversations/1/messages/9/image",
                width: RemoteFlexibleString(String(width)), height: RemoteFlexibleString(String(height)),
                size: RemoteFlexibleString(String(size)), contentType: "image/jpeg"
            )
            XCTAssertThrowsError(try SocialRemoteMapper.mapImageMetadata(dto))
        }
    }

    func testMapConversationDefaultsImageMessagingEnabledToFalse() throws {
        let peer = SocialUserRemoteDTO(
            id: "user-1",
            nickname: "小林",
            avatarUrl: nil,
            introduction: nil,
            followingCount: nil,
            followerCount: nil,
            friendCount: nil,
            relationship: "MUTUAL",
            blockedByMe: false,
            canMessage: true,
            messagePermissionReason: nil
        )
        let dto = ConversationRemoteDTO(
            id: "c1",
            peer: peer,
            lastMessage: nil,
            updatedAt: "2026-10-05T10:00:00+08:00",
            unreadCount: RemoteFlexibleString("0"),
            lastReadSeq: RemoteFlexibleString("0"),
            canSend: true,
            sendPermissionReason: nil,
            imageMessagingEnabled: nil
        )
        let mapped = try SocialRemoteMapper.mapConversation(dto)
        XCTAssertFalse(mapped.imageMessagingEnabled)
    }

    func testMapConversationRejectsMissingPeerAndDoesNotInventConversationID() {
        let dto = ConversationRemoteDTO(
            id: nil,
            peer: nil,
            lastMessage: nil,
            updatedAt: "2026-10-05T10:00:00+08:00",
            unreadCount: RemoteFlexibleString("0"),
            lastReadSeq: RemoteFlexibleString("0"),
            canSend: true,
            sendPermissionReason: nil,
            imageMessagingEnabled: nil
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapConversation(dto)) { error in
            XCTAssertEqual(error as? SocialMappingError, .missingRequiredField("id"))
        }

        let missingPeer = ConversationRemoteDTO(
            id: "c1",
            peer: nil,
            lastMessage: nil,
            updatedAt: "2026-10-05T10:00:00+08:00",
            unreadCount: RemoteFlexibleString("0"),
            lastReadSeq: RemoteFlexibleString("0"),
            canSend: true,
            sendPermissionReason: nil,
            imageMessagingEnabled: false
        )
        XCTAssertThrowsError(try SocialRemoteMapper.mapConversation(missingPeer)) { error in
            XCTAssertEqual(error as? SocialMappingError, .missingRequiredField("peer"))
        }
    }

    func testPageMappingFiltersMalformedItemsWithoutInventingIdentity() {
        let page = SocialRemoteMapper.mapUserPage(
            SocialPageRemoteDTO(
                items: [
                    SocialUserRemoteDTO(
                        id: nil,
                        nickname: "bad",
                        avatarUrl: nil,
                        introduction: nil,
                        followingCount: nil,
                        followerCount: nil,
                        friendCount: nil,
                        relationship: "NONE",
                        blockedByMe: false,
                        canMessage: false,
                        messagePermissionReason: nil
                    ),
                    SocialUserRemoteDTO(
                        id: "user-ok",
                        nickname: "ok",
                        avatarUrl: nil,
                        introduction: nil,
                        followingCount: RemoteFlexibleString("1"),
                        followerCount: RemoteFlexibleString("2"),
                        friendCount: RemoteFlexibleString("0"),
                        relationship: "FOLLOWING",
                        blockedByMe: false,
                        canMessage: true,
                        messagePermissionReason: nil
                    )
                ],
                nextCursor: "user-ok",
                hasMore: false
            )
        )

        XCTAssertEqual(page.items.map(\.id), ["user-ok"])
        XCTAssertEqual(page.nextCursor, "user-ok")
    }

    func testMapMessagePageFiltersMalformedMessages() {
        let page = SocialRemoteMapper.mapMessagePage(
            SocialPageRemoteDTO(
                items: [
                    ChatMessageRemoteDTO(
                        id: nil,
                        conversationId: "c1",
                        seq: RemoteFlexibleString("1"),
                        senderId: "a",
                        clientMessageId: "cid-1",
                        type: nil,
                        content: "bad",
                        createdAt: "2026-10-05T10:00:00+08:00",
                        image: nil
                    ),
                    ChatMessageRemoteDTO(
                        id: "2",
                        conversationId: "c1",
                        seq: RemoteFlexibleString("2"),
                        senderId: "b",
                        clientMessageId: "cid-2",
                        type: nil,
                        content: "hello",
                        createdAt: "2026-10-05T10:01:00+08:00",
                        image: nil
                    )
                ],
                nextCursor: "2",
                hasMore: true
            )
        )

        XCTAssertEqual(page.items.map(\.id), ["2"])
        XCTAssertEqual(page.items.map(\.seq), ["2"])
    }

    func testDirectMessagePolicyDefaultsUnknownToMutualNotAll() {
        XCTAssertEqual(DirectMessagePolicy.resolved(nil), .mutual)
        XCTAssertEqual(DirectMessagePolicy.resolved("UNKNOWN"), .mutual)
        XCTAssertEqual(DirectMessagePolicy.resolved("all"), .all)
        XCTAssertEqual(DirectMessagePolicy.resolved("FOLLOWING"), .following)
        XCTAssertEqual(DirectMessagePolicy.resolved("NONE"), .none)
    }

    func testSanitizedMessageContentUsesUnicodeScalarCountForEmojiZWJBoundary() {
        let family = "👨‍👩‍👧‍👦"
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(family.unicodeScalars.count, 7)

        XCTAssertNil(SocialRemoteMapper.sanitizedMessageContent("   "))
        XCTAssertEqual(SocialRemoteMapper.sanitizedMessageContent("  hi  "), "hi")

        let tooLongByScalars = String(repeating: "a", count: 994) + family
        XCTAssertEqual(tooLongByScalars.unicodeScalars.count, 1001)
        XCTAssertEqual(tooLongByScalars.count, 995)
        XCTAssertNil(SocialRemoteMapper.sanitizedMessageContent(tooLongByScalars))

        let exactlyLimitByScalars = String(repeating: "a", count: 993) + family
        XCTAssertEqual(exactlyLimitByScalars.unicodeScalars.count, 1000)
        XCTAssertNotNil(SocialRemoteMapper.sanitizedMessageContent(exactlyLimitByScalars))

        XCTAssertNil(SocialRemoteMapper.sanitizedMessageContent(String(repeating: "啊", count: 1001)))
        XCTAssertNotNil(SocialRemoteMapper.sanitizedMessageContent(String(repeating: "啊", count: 1000)))
    }
}
