import XCTest
@testable import GdeiAssistant_iOS

final class ChatMessageMergeTests: XCTestCase {
    func testTwoSendersSharingClientMessageIdRemainDistinct() {
        let sharedClientID = "same-client-uuid"
        let fromA = committed(
            id: "msg-a",
            seq: "10",
            senderId: "user-a",
            clientMessageId: sharedClientID,
            content: "from A"
        )
        let fromB = committed(
            id: "msg-b",
            seq: "11",
            senderId: "user-b",
            clientMessageId: sharedClientID,
            content: "from B"
        )

        let merged = ChatMessageMerge.merge([fromA, fromB])

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(Set(merged.map(\.id)), Set(["msg-a", "msg-b"]))
        XCTAssertEqual(Set(merged.map(\.senderId)), Set(["user-a", "user-b"]))
    }

    func testWebSocketThenRESTCollapseToSameCommittedMessage() {
        let clientID = "client-1"
        let pending = local(
            id: "pending-\(clientID)",
            senderId: "me",
            clientMessageId: clientID,
            content: "hello",
            deliveryState: .pending
        )
        let fromWS = committed(
            id: "server-1",
            seq: "42",
            senderId: "me",
            clientMessageId: clientID,
            content: "hello",
            createdAt: "2026-10-05T12:00:01+08:00"
        )
        let fromREST = committed(
            id: "server-1",
            seq: "42",
            senderId: "me",
            clientMessageId: clientID,
            content: "hello",
            createdAt: "2026-10-05T12:00:01+08:00"
        )

        let afterWS = ChatMessageMerge.merge([pending, fromWS])
        XCTAssertEqual(afterWS.count, 1)
        XCTAssertEqual(afterWS.first?.id, "server-1")
        XCTAssertEqual(afterWS.first?.deliveryState, .sent)

        let afterREST = ChatMessageMerge.merge(afterWS + [fromREST])
        XCTAssertEqual(afterREST.count, 1)
        XCTAssertEqual(afterREST.first?.id, "server-1")
        XCTAssertEqual(afterREST.first?.seq, "42")
    }

    func testReplaceLocalBubbleDoesNotDropPeerMessageWithSameClientId() {
        let sharedClientID = "shared"
        let peer = committed(
            id: "peer-1",
            seq: "5",
            senderId: "peer",
            clientMessageId: sharedClientID,
            content: "peer text"
        )
        let pending = local(
            id: "pending-\(sharedClientID)",
            senderId: "me",
            clientMessageId: sharedClientID,
            content: "mine",
            deliveryState: .pending
        )
        let sent = committed(
            id: "mine-1",
            seq: "6",
            senderId: "me",
            clientMessageId: sharedClientID,
            content: "mine"
        )

        let result = ChatMessageMerge.replaceLocalBubble(
            in: [peer, pending],
            senderId: "me",
            clientMessageId: sharedClientID,
            with: sent
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map(\.id)), Set(["peer-1", "mine-1"]))
    }

    func testPendingDoesNotAdvanceCommittedCursorPastRealNextSeq() {
        let sentTen = committed(
            id: "m10",
            seq: "10",
            senderId: "peer",
            clientMessageId: "c10",
            content: "ten"
        )
        let pending = local(
            id: "pending-mine",
            senderId: "me",
            clientMessageId: "c-pending",
            content: "pending",
            deliveryState: .pending
        )
        let failed = local(
            id: "failed-mine",
            senderId: "me",
            clientMessageId: "c-failed",
            content: "failed",
            deliveryState: .failed
        )

        let cursor = ChatMessageMerge.latestCommittedSeq([sentTen, pending, failed])
        XCTAssertEqual(cursor, "10")

        // afterSeq stays at 10, so a real server message with seq=11 remains pullable.
        let next = committed(
            id: "m11",
            seq: "11",
            senderId: "peer",
            clientMessageId: "c11",
            content: "eleven"
        )
        let merged = ChatMessageMerge.merge([sentTen, pending, failed, next])
        XCTAssertEqual(ChatMessageMerge.latestCommittedSeq(merged), "11")
        XCTAssertTrue(merged.contains(where: { $0.id == "m11" }))
        XCTAssertTrue(merged.contains(where: { $0.deliveryState == .pending }))
        XCTAssertTrue(merged.contains(where: { $0.deliveryState == .failed }))
    }

    func testLatestCommittedPeerSeqIgnoresPendingAndOwnMessages() {
        let own = committed(
            id: "own",
            seq: "20",
            senderId: "me",
            clientMessageId: "own-c",
            content: "own"
        )
        let peer = committed(
            id: "peer",
            seq: "18",
            senderId: "peer",
            clientMessageId: "peer-c",
            content: "peer"
        )
        let pending = local(
            id: "pending",
            senderId: "peer",
            clientMessageId: "peer-pending",
            content: "not committed",
            deliveryState: .pending
        )

        let seq = ChatMessageMerge.latestCommittedPeerSeq(
            [own, peer, pending],
            excludingSenderId: "me"
        )
        XCTAssertEqual(seq, "18")
    }

    func testSortedKeepsLocalBubblesAfterCommittedRows() {
        let sent = committed(
            id: "m1",
            seq: "1",
            senderId: "peer",
            clientMessageId: "c1",
            content: "one",
            createdAt: "2026-10-05T12:00:00+08:00"
        )
        let pending = local(
            id: "pending",
            senderId: "me",
            clientMessageId: "c2",
            content: "pending",
            deliveryState: .pending,
            createdAt: "2026-10-05T11:00:00+08:00"
        )

        let sorted = ChatMessageMerge.sorted([pending, sent])
        XCTAssertEqual(sorted.map(\.id), ["m1", "pending"])
    }

    func testAutoScrollFirstLoadGoesToBottom() {
        let loaded = [
            committed(id: "1", seq: "1", senderId: "a", clientMessageId: "c1", content: "one"),
            committed(id: "2", seq: "2", senderId: "b", clientMessageId: "c2", content: "two")
        ]
        XCTAssertEqual(
            ChatThreadAutoScroll.action(previous: [], current: loaded),
            .scrollToBottom(messageID: "2")
        )
    }

    func testAutoScrollAppendAtTailGoesToBottom() {
        let previous = [
            committed(id: "1", seq: "1", senderId: "a", clientMessageId: "c1", content: "one"),
            committed(id: "2", seq: "2", senderId: "b", clientMessageId: "c2", content: "two")
        ]
        let current = previous + [
            committed(id: "3", seq: "3", senderId: "a", clientMessageId: "c3", content: "three")
        ]
        XCTAssertEqual(
            ChatThreadAutoScroll.action(previous: previous, current: current),
            .scrollToBottom(messageID: "3")
        )
    }

    func testAutoScrollPendingReplacedAtTailGoesToNewId() {
        let pending = local(
            id: "pending-c1",
            senderId: "me",
            clientMessageId: "c1",
            content: "hello",
            deliveryState: .pending
        )
        let previous = [
            committed(id: "1", seq: "1", senderId: "peer", clientMessageId: "c0", content: "hi"),
            pending
        ]
        let current = [
            committed(id: "1", seq: "1", senderId: "peer", clientMessageId: "c0", content: "hi"),
            committed(id: "server-9", seq: "9", senderId: "me", clientMessageId: "c1", content: "hello")
        ]
        XCTAssertEqual(
            ChatThreadAutoScroll.action(previous: previous, current: current),
            .scrollToBottom(messageID: "server-9")
        )
    }

    func testAutoScrollLoadEarlierPrependPreservesOldFirst() {
        let previous = [
            committed(id: "10", seq: "10", senderId: "a", clientMessageId: "c10", content: "ten"),
            committed(id: "11", seq: "11", senderId: "b", clientMessageId: "c11", content: "eleven")
        ]
        let current = [
            committed(id: "8", seq: "8", senderId: "a", clientMessageId: "c8", content: "eight"),
            committed(id: "9", seq: "9", senderId: "b", clientMessageId: "c9", content: "nine")
        ] + previous

        XCTAssertEqual(
            ChatThreadAutoScroll.action(previous: previous, current: current),
            .preserve(messageID: "10")
        )
        XCTAssertEqual(ChatThreadAutoScroll.trailingIdentity(of: previous), "11")
        XCTAssertEqual(ChatThreadAutoScroll.trailingIdentity(of: current), "11")
    }

    func testAutoScrollUnchangedTailDoesNothing() {
        let messages = [
            committed(id: "1", seq: "1", senderId: "a", clientMessageId: "c1", content: "one"),
            committed(id: "2", seq: "2", senderId: "b", clientMessageId: "c2", content: "two")
        ]
        XCTAssertEqual(
            ChatThreadAutoScroll.action(previous: messages, current: messages),
            .none
        )
    }

    func testUpdateLocalBubbleStateDoesNotDemoteAlreadySent() {
        let sent = committed(id: "server-1", seq: "5", senderId: "me", clientMessageId: "c-retry", content: "hi")
        let updated = ChatMessageMerge.updateLocalBubbleState(
            in: [sent],
            senderId: "me",
            clientMessageId: "c-retry",
            deliveryState: .failed
        )
        XCTAssertEqual(updated.first?.deliveryState, .sent)
        XCTAssertTrue(
            ChatMessageMerge.hasCommittedSend(in: updated, senderId: "me", clientMessageId: "c-retry")
        )
    }

    // MARK: - Helpers

    private func committed(
        id: String,
        seq: String,
        senderId: String,
        clientMessageId: String,
        content: String,
        createdAt: String = "2026-10-05T12:00:00+08:00"
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationId: "conv-1",
            seq: seq,
            senderId: senderId,
            clientMessageId: clientMessageId,
            content: content,
            createdAt: createdAt,
            deliveryState: .sent
        )
    }

    private func local(
        id: String,
        senderId: String,
        clientMessageId: String,
        content: String,
        deliveryState: ChatDeliveryState,
        createdAt: String = "2026-10-05T12:00:02+08:00"
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            conversationId: "conv-1",
            seq: "",
            senderId: senderId,
            clientMessageId: clientMessageId,
            content: content,
            createdAt: createdAt,
            deliveryState: deliveryState
        )
    }
}
