import UIKit
import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MockSocialRepositoryTests: XCTestCase {
    func testFollowUnfollowAndMutualFriendFlow() async throws {
        let repository = MockSocialRepository()
        let me = try await repository.fetchMe()
        XCTAssertEqual(me.relationship, .selfRelation)

        let aliceBefore = try await repository.fetchUser(id: "user-alice-0002")
        XCTAssertEqual(aliceBefore.relationship, .mutual)

        let unfollowed = try await repository.unfollow(userID: aliceBefore.id)
        XCTAssertEqual(unfollowed.relationship, .followedBy)

        let followed = try await repository.follow(userID: aliceBefore.id)
        XCTAssertEqual(followed.relationship, .mutual)

        let friends = try await repository.fetchRelationships(
            userID: me.id,
            kind: .friends,
            cursor: nil,
            limit: 20
        )
        XCTAssertTrue(friends.items.contains(where: { $0.id == aliceBefore.id }))
    }

    func testBlockRemovesFollowAndMessagePermission() async throws {
        let repository = MockSocialRepository()
        let blocked = try await repository.block(userID: "user-alice-0002")
        XCTAssertTrue(blocked.blocked)

        let alice = try await repository.fetchUser(id: "user-alice-0002")
        XCTAssertTrue(alice.blockedByMe)
        XCTAssertFalse(alice.canMessage)
        XCTAssertEqual(alice.relationship, .none)

        do {
            _ = try await repository.createConversation(peerID: alice.id)
            XCTFail("Expected privacy/contact failure")
        } catch let error as NetworkError {
            XCTAssertTrue(
                error.errorCode == SocialErrorCode.privacyRestricted
                    || error.errorCode == SocialErrorCode.contactUnavailable
            )
        }

        _ = try await repository.unblock(userID: alice.id)
        let restored = try await repository.fetchUser(id: alice.id)
        XCTAssertFalse(restored.blockedByMe)
        XCTAssertFalse(restored.isFollowing)
    }

    func testSendMessageRetrySameClientMessageIdIsIdempotent() async throws {
        let repository = MockSocialRepository()
        let conversation = try await repository.createConversation(peerID: "user-alice-0002")
        let clientMessageID = UUID().uuidString
        let first = try await repository.sendMessage(
            conversationID: conversation.id,
            clientMessageID: clientMessageID,
            content: "hello"
        )
        let second = try await repository.sendMessage(
            conversationID: conversation.id,
            clientMessageID: clientMessageID,
            content: "hello"
        )
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.seq, second.seq)

        do {
            _ = try await repository.sendMessage(
                conversationID: conversation.id,
                clientMessageID: clientMessageID,
                content: "different"
            )
            XCTFail("Expected conflict")
        } catch let error as NetworkError {
            XCTAssertEqual(error.errorCode, SocialErrorCode.clientMessageConflict)
        }
    }

    func testSendImageMessageIdempotentAndConflictOnDifferentPayload() async throws {
        let repository = MockSocialRepository()
        let conversation = try await repository.createConversation(peerID: "user-alice-0002")
        XCTAssertTrue(conversation.imageMessagingEnabled)

        let jpeg = MockSocialSeed.seedJPEGData
        XCTAssertFalse(jpeg.isEmpty, "Seed JPEG must be real bytes, not an empty success stub")

        let clientMessageID = UUID().uuidString
        let first = try await repository.sendImageMessage(
            conversationID: conversation.id,
            clientMessageID: clientMessageID,
            imageData: jpeg,
            fileName: "chat-\(clientMessageID).jpg",
            mimeType: "image/jpeg"
        )
        XCTAssertEqual(first.type, .image)
        XCTAssertEqual(first.content, "")
        XCTAssertNotNil(first.image)

        let second = try await repository.sendImageMessage(
            conversationID: conversation.id,
            clientMessageID: clientMessageID,
            imageData: jpeg,
            fileName: "chat-\(clientMessageID).jpg",
            mimeType: "image/jpeg"
        )
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.seq, second.seq)

        let otherJPEG = UIImage(systemName: "photo")!.jpegData(compressionQuality: 0.8)!
        do {
            _ = try await repository.sendImageMessage(
                conversationID: conversation.id,
                clientMessageID: clientMessageID,
                imageData: otherJPEG,
                fileName: "chat-\(clientMessageID).jpg",
                mimeType: "image/jpeg"
            )
            XCTFail("Expected conflict for different image bytes")
        } catch let error as NetworkError {
            XCTAssertEqual(error.errorCode, SocialErrorCode.clientMessageConflict)
        }

        let refreshed = try await repository.fetchConversation(id: conversation.id)
        XCTAssertEqual(refreshed.lastMessage?.type, .image)
        XCTAssertEqual(refreshed.lastMessage?.previewText, localizedString("social.chat.imageSummary"))
    }

    func testCommittedImageRetryAndReadStillWorkAfterBlock() async throws {
        let repository = MockSocialRepository()
        let conversation = try await repository.createConversation(peerID: MockSocialSeed.aliceID)
        let id = UUID().uuidString
        let bytes = MockSocialSeed.seedJPEGData
        let first = try await repository.sendImageMessage(
            conversationID: conversation.id, clientMessageID: id, imageData: bytes,
            fileName: "image.jpg", mimeType: "image/jpeg"
        )
        _ = try await repository.block(userID: MockSocialSeed.aliceID)
        let confirmed = try await repository.sendImageMessage(
            conversationID: conversation.id, clientMessageID: id, imageData: bytes,
            fileName: "image.jpg", mimeType: "image/jpeg"
        )
        XCTAssertEqual(confirmed.id, first.id)
        XCTAssertEqual(repository.imageData(for: first.image!.url), bytes)
        XCTAssertNil(repository.imageData(for: "/api/social/conversations/999/messages/\(first.id)/image"))
        do {
            _ = try await repository.sendImageMessage(
                conversationID: conversation.id, clientMessageID: UUID().uuidString, imageData: bytes,
                fileName: "image.jpg", mimeType: "image/jpeg"
            )
            XCTFail("A new image must respect the latest privacy/block state")
        } catch let error as NetworkError {
            XCTAssertEqual(error.errorCode, SocialErrorCode.privacyRestricted)
        }
    }

    func testSendImageMessageRejectsEmptyOrOversizedPayload() async throws {
        let repository = MockSocialRepository()
        let conversation = try await repository.createConversation(peerID: "user-alice-0002")
        do {
            _ = try await repository.sendImageMessage(
                conversationID: conversation.id,
                clientMessageID: UUID().uuidString,
                imageData: Data(),
                fileName: "empty.jpg",
                mimeType: "image/jpeg"
            )
            XCTFail("Empty image must fail")
        } catch let error as NetworkError {
            XCTAssertEqual(error.errorCode, SocialErrorCode.invalidRequest)
        }
    }

    func testPrivacyDefaultMutualAndUnknownResolvedOutsideMapper() async throws {
        let repository = MockSocialRepository()
        let privacy = try await repository.fetchPrivacy()
        XCTAssertEqual(privacy.dmPolicy, .mutual)

        let updated = try await repository.updatePrivacy(.following)
        XCTAssertEqual(updated.dmPolicy, .following)
    }

    func testSearchAndConversationPaginationBasics() async throws {
        let repository = MockSocialRepository()
        let users = try await repository.searchUsers(query: "小", cursor: nil, limit: 20)
        XCTAssertFalse(users.items.isEmpty)

        let conversations = try await repository.fetchConversations(cursor: nil, limit: 20)
        XCTAssertFalse(conversations.items.isEmpty)

        let conversationID = conversations.items[0].id
        let messages = try await repository.fetchMessages(
            conversationID: conversationID,
            beforeSeq: nil,
            afterSeq: nil,
            limit: 20
        )
        XCTAssertFalse(messages.items.isEmpty)
        XCTAssertEqual(messages.items.map(\.seqValue), messages.items.map(\.seqValue).sorted())
    }
}
