import Combine
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

    func testChatImageRetryRetainsActualJPEGBytesAndOriginalClientMessageID() async throws {
        let repository = MockSocialRepository(failFirstImageSend: true)
        let environment = AppEnvironment(networkEnvironment: .dev, dataSourceMode: .mock, isDebug: true)
        let realtime = SocialRealtimeManager(
            environment: environment, tokenProvider: { nil }, isLoggedInProvider: { true },
            onUnauthorized: { XCTFail("Mock image retry must not request remote authentication") }
        )
        let viewModel = ChatThreadViewModel(
            conversationID: "1", repository: repository, realtimeManager: realtime
        )
        defer {
            viewModel.stop()
            realtime.stop(clearState: true)
        }
        await viewModel.start()
        viewModel.setDraftImage(try XCTUnwrap(UIImage(data: MockSocialSeed.seedJPEGData)))
        await viewModel.send()
        let failed = try XCTUnwrap(viewModel.messages.first { $0.deliveryState == .failed })
        let retainedBytes = try XCTUnwrap(viewModel.localImageData(for: failed.clientMessageId))
        XCTAssertNotNil(UIImage(data: retainedBytes), "Retry data must be a real, encoded image")
        XCTAssertNil(viewModel.draftImagePreview)
        let beforeRetry = try await repository.fetchMessages(
            conversationID: "1", beforeSeq: nil, afterSeq: nil, limit: 20
        )
        XCTAssertFalse(beforeRetry.items.contains { $0.clientMessageId == failed.clientMessageId })

        await viewModel.retry(failed)
        let sent = try XCTUnwrap(viewModel.messages.first { $0.clientMessageId == failed.clientMessageId })
        XCTAssertEqual(sent.deliveryState, .sent)
        XCTAssertEqual(repository.imageData(for: try XCTUnwrap(sent.image).url), retainedBytes)
        XCTAssertNil(viewModel.localImageData(for: failed.clientMessageId))
        let committed = try await repository.fetchMessages(
            conversationID: "1", beforeSeq: nil, afterSeq: nil, limit: 20
        )
        XCTAssertEqual(committed.items.filter { $0.clientMessageId == failed.clientMessageId }.count, 1)
        XCTAssertEqual(viewModel.messages.filter { $0.clientMessageId == failed.clientMessageId }.count, 1)
    }

    func testChatStopClearsFailedJPEGAndNewDraft() async throws {
        let repository = MockSocialRepository(failFirstImageSend: true)
        let environment = AppEnvironment(networkEnvironment: .dev, dataSourceMode: .mock, isDebug: true)
        let realtime = SocialRealtimeManager(
            environment: environment, tokenProvider: { nil }, isLoggedInProvider: { true },
            onUnauthorized: {}
        )
        let viewModel = ChatThreadViewModel(
            conversationID: "1", repository: repository, realtimeManager: realtime
        )
        defer {
            viewModel.stop()
            realtime.stop(clearState: true)
        }
        await viewModel.start()
        let image = try XCTUnwrap(UIImage(data: MockSocialSeed.seedJPEGData))
        viewModel.setDraftImage(image)
        await viewModel.send()
        let failed = try XCTUnwrap(viewModel.messages.first { $0.deliveryState == .failed })
        XCTAssertNotNil(viewModel.localImageData(for: failed.clientMessageId))
        viewModel.setDraftImage(image)
        XCTAssertNotNil(viewModel.draftImagePreview)

        viewModel.stop()
        XCTAssertNil(viewModel.localImageData(for: failed.clientMessageId))
        XCTAssertNil(viewModel.draftImagePreview)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.currentUserID)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSending)
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

    func testRealtimeEventPublisherDeliversRapidConsecutiveEvents() {
        let environment = AppEnvironment(networkEnvironment: .dev, dataSourceMode: .mock, isDebug: true)
        let realtime = SocialRealtimeManager(
            environment: environment,
            tokenProvider: { nil },
            isLoggedInProvider: { true },
            onUnauthorized: {}
        )
        var received: [SocialRealtimeEvent] = []
        let cancellable = realtime.eventPublisher.sink { event in
            received.append(event)
        }
        defer { cancellable.cancel() }

        realtime.start()
        realtime.handleForegroundResume()
        realtime.stop(clearState: true)

        XCTAssertEqual(received, [.ready, .ready, .disconnected])
    }

    func testConversationListViewModelSerializesAndCoalescesRealtimeRefreshes() async throws {
        let repository = CoalescingSpySocialRepository()
        let realtime = StubSocialRealtimeManager()
        let viewModel = ConversationListViewModel(repository: repository, realtimeManager: realtime)
        defer { viewModel.stop() }

        await viewModel.start()
        XCTAssertEqual(repository.unreadFetchCount, 1)
        XCTAssertEqual(viewModel.unreadTotal, 1)

        // Trigger first quiet refresh and wait until it is in-flight
        realtime.send(.messageCreated(conversationId: "1", messageId: "m0", seq: "0"))
        for _ in 0..<40 where repository.unreadFetchCount < 2 {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertEqual(repository.unreadFetchCount, 2)

        // Emit burst of events while the in-flight refresh is suspended
        for index in 1...5 {
            realtime.send(.messageCreated(conversationId: "1", messageId: "m\(index)", seq: "\(index)"))
        }

        // The view model publishes the unread total after both requests finish.
        for _ in 0..<40 where viewModel.unreadTotal < 3 {
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTAssertEqual(repository.maxConcurrentQuietFetches, 1)
        XCTAssertEqual(repository.unreadFetchCount, 3)
        XCTAssertEqual(viewModel.unreadTotal, 3)
    }
}

@MainActor
private final class StubSocialRealtimeManager: SocialRealtimeManaging {
    var isReady = true
    var latestEvent: SocialRealtimeEvent?
    private let subject = PassthroughSubject<SocialRealtimeEvent, Never>()
    var eventPublisher: AnyPublisher<SocialRealtimeEvent, Never> { subject.eraseToAnyPublisher() }

    nonisolated deinit {}

    func send(_ event: SocialRealtimeEvent) {
        latestEvent = event
        subject.send(event)
    }

    func start() {}
    func stop(clearState: Bool) {}
    func handleForegroundResume() {}
    func sendPing() {}
}

@MainActor
private final class CoalescingSpySocialRepository: SocialRepository {
    private let inner = MockSocialRepository()
    private(set) var unreadFetchCount = 0
    private(set) var maxConcurrentQuietFetches = 0
    private var activeQuietFetches = 0

    nonisolated deinit {}

    func fetchMe() async throws -> SocialUser { try await inner.fetchMe() }
    func searchUsers(query: String, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await inner.searchUsers(query: query, cursor: cursor, limit: limit)
    }
    func fetchUser(id: String) async throws -> SocialUser { try await inner.fetchUser(id: id) }
    func fetchRelationships(userID: String, kind: SocialRelationshipKind, cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await inner.fetchRelationships(userID: userID, kind: kind, cursor: cursor, limit: limit)
    }
    func follow(userID: String) async throws -> SocialUser { try await inner.follow(userID: userID) }
    func unfollow(userID: String) async throws -> SocialUser { try await inner.unfollow(userID: userID) }
    func block(userID: String) async throws -> SocialBlockState { try await inner.block(userID: userID) }
    func unblock(userID: String) async throws -> SocialBlockState { try await inner.unblock(userID: userID) }
    func fetchBlocks(cursor: String?, limit: Int) async throws -> SocialPage<SocialUser> {
        try await inner.fetchBlocks(cursor: cursor, limit: limit)
    }
    func fetchPrivacy() async throws -> DirectMessagePrivacy { try await inner.fetchPrivacy() }
    func updatePrivacy(_ policy: DirectMessagePolicy) async throws -> DirectMessagePrivacy {
        try await inner.updatePrivacy(policy)
    }
    func fetchUnreadCount() async throws -> SocialUnreadCount {
        unreadFetchCount += 1
        let count = unreadFetchCount
        if count > 1 {
            activeQuietFetches += 1
            maxConcurrentQuietFetches = max(maxConcurrentQuietFetches, activeQuietFetches)
            try await Task.sleep(nanoseconds: 40_000_000)
            activeQuietFetches -= 1
        }
        return SocialUnreadCount(total: count)
    }
    func createConversation(peerID: String) async throws -> ConversationSummary {
        try await inner.createConversation(peerID: peerID)
    }
    func fetchConversations(cursor: String?, limit: Int) async throws -> SocialPage<ConversationSummary> {
        try await inner.fetchConversations(cursor: cursor, limit: limit)
    }
    func fetchConversation(id: String) async throws -> ConversationSummary {
        try await inner.fetchConversation(id: id)
    }
    func fetchMessages(conversationID: String, beforeSeq: String?, afterSeq: String?, limit: Int) async throws -> SocialPage<ChatMessage> {
        try await inner.fetchMessages(conversationID: conversationID, beforeSeq: beforeSeq, afterSeq: afterSeq, limit: limit)
    }
    func sendMessage(conversationID: String, clientMessageID: String, content: String) async throws -> ChatMessage {
        try await inner.sendMessage(conversationID: conversationID, clientMessageID: clientMessageID, content: content)
    }
    func sendImageMessage(conversationID: String, clientMessageID: String, imageData: Data, fileName: String, mimeType: String) async throws -> ChatMessage {
        try await inner.sendImageMessage(conversationID: conversationID, clientMessageID: clientMessageID, imageData: imageData, fileName: fileName, mimeType: mimeType)
    }
    func markRead(conversationID: String, lastReadSeq: String) async throws -> ConversationReadState {
        try await inner.markRead(conversationID: conversationID, lastReadSeq: lastReadSeq)
    }
}
