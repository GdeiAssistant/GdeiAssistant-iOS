import XCTest
@testable import GdeiAssistant_iOS

final class MessagesRemoteMapperTests: XCTestCase {
    func testMapInteractionItemsNormalizesKnownModuleAliasesCaseInsensitively() throws {
        let item = InteractionNotificationRemoteDTO(
            id: " interaction-1 ",
            module: " Roommate ",
            type: " Comment ",
            title: nil,
            content: nil,
            createdAt: RemoteFlexibleString("1704067200"),
            isRead: nil,
            targetType: " sent ",
            targetId: " 88 ",
            targetSubId: " 99 "
        )

        let mapped = try XCTUnwrap(MessagesRemoteMapper.mapInteractionItems([item]).first)

        XCTAssertEqual(mapped.id, "interaction-1")
        XCTAssertEqual(mapped.category, .comment)
        XCTAssertEqual(mapped.module, "dating")
        XCTAssertEqual(mapped.title, localizedString("feature.dating"))
        XCTAssertEqual(mapped.message, localizedString("messages.mapper.newInteractionMessage"))
        XCTAssertEqual(mapped.createdAt, "2024-01-01 08:00")
        XCTAssertEqual(mapped.destination, .datingCenter)
        XCTAssertEqual(mapped.targetType, "sent")
        XCTAssertEqual(mapped.targetID, "88")
        XCTAssertEqual(mapped.targetSubID, "99")
        XCTAssertFalse(mapped.isRead)
    }

    func testMapInteractionItemsFiltersEntriesWithoutValidID() {
        let missingID = InteractionNotificationRemoteDTO(
            id: nil,
            module: "marketplace",
            type: "like",
            title: nil,
            content: nil,
            createdAt: nil,
            isRead: nil,
            targetType: nil,
            targetId: nil,
            targetSubId: nil
        )
        let blankID = InteractionNotificationRemoteDTO(
            id: "   ",
            module: "topic",
            type: "comment",
            title: nil,
            content: nil,
            createdAt: nil,
            isRead: nil,
            targetType: nil,
            targetId: nil,
            targetSubId: nil
        )

        XCTAssertTrue(MessagesRemoteMapper.mapInteractionItems([missingID, blankID]).isEmpty)
    }

    func testMapAnnouncementItemsFiltersMissingIDsAndKeepsFallbacksForValidID() {
        let dirtyItem = AnnouncementRemoteDTO(
            id: "  ",
            title: nil,
            content: nil,
            publishTime: nil
        )
        let validItem = AnnouncementRemoteDTO(
            id: " notice-42 ",
            title: nil,
            content: nil,
            publishTime: nil
        )

        let mapped = MessagesRemoteMapper.mapAnnouncementItems([dirtyItem, validItem])

        XCTAssertEqual(mapped.count, 1)
        XCTAssertEqual(mapped[0].id, "notice-42")
        XCTAssertEqual(mapped[0].category, .system)
        XCTAssertEqual(mapped[0].title, localizedString("messages.mapper.announcementTitle"))
        XCTAssertEqual(mapped[0].message, localizedString("messages.mapper.announcementEmptyContent"))
        XCTAssertEqual(mapped[0].createdAt, localizedString("common.justNow"))
        XCTAssertEqual(mapped[0].destination, .announcement)
        XCTAssertEqual(mapped[0].targetID, "notice-42")
    }

    func testMapAnnouncementDetailRequiresValidIDOrFallback() throws {
        let missingID = AnnouncementRemoteDTO(
            id: " ",
            title: "Notice",
            content: "Body",
            publishTime: nil
        )

        XCTAssertThrowsError(try MessagesRemoteMapper.mapAnnouncementDetail(missingID))

        let resolved = try MessagesRemoteMapper.mapAnnouncementDetail(missingID, fallbackID: "notice-9")
        XCTAssertEqual(resolved.id, "notice-9")
        XCTAssertEqual(resolved.title, "Notice")
    }

    @MainActor
    func testNotificationListViewModelsAdvanceOffsetByRawFetchedCount() async throws {
        let stub = PaginatedMessagesStubRepository()
        let noticeVM = SystemNoticeListViewModel(repository: stub)

        await noticeVM.refresh()
        XCTAssertEqual(noticeVM.items.map(\.id), ["a1", "a2", "a3", "a4"])
        XCTAssertTrue(noticeVM.canLoadMore)

        let lastNotice = try XCTUnwrap(noticeVM.items.last)
        await noticeVM.loadMoreIfNeeded(currentItem: lastNotice)
        XCTAssertEqual(stub.announcementStarts, [0, 5])
        XCTAssertEqual(noticeVM.items.map(\.id), ["a1", "a2", "a3", "a4", "a5"])
        XCTAssertFalse(noticeVM.canLoadMore)

        let interactionVM = InteractionMessageListViewModel(repository: stub)
        await interactionVM.refresh()
        XCTAssertEqual(interactionVM.items.map(\.id), ["i1", "i2", "i3", "i4"])
        XCTAssertTrue(interactionVM.canLoadMore)

        let lastInteraction = try XCTUnwrap(interactionVM.items.last)
        await interactionVM.loadMoreIfNeeded(currentItem: lastInteraction)
        XCTAssertEqual(stub.interactionStarts, [0, 5])
        XCTAssertEqual(interactionVM.items.map(\.id), ["i1", "i2", "i3", "i4", "i5"])
        XCTAssertFalse(interactionVM.canLoadMore)
    }
}

@MainActor
private final class PaginatedMessagesStubRepository: MessagesRepository {
    var announcementStarts: [Int] = []
    var interactionStarts: [Int] = []

    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await fetchAnnouncementBatch(start: start, size: size).items
    }

    func fetchAnnouncementBatch(start: Int, size: Int) async throws -> NotificationPage {
        announcementStarts.append(start)
        if start == 0 {
            return NotificationPage(
                items: ["a1", "a2", "a3", "a4"].map(makeAnnouncementItem(id:)),
                fetchedCount: 5
            )
        }
        return NotificationPage(items: [makeAnnouncementItem(id: "a5")], fetchedCount: 1)
    }

    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await fetchInteractionBatch(start: start, size: size).items
    }

    func fetchInteractionBatch(start: Int, size: Int) async throws -> NotificationPage {
        interactionStarts.append(start)
        if start == 0 {
            return NotificationPage(
                items: ["i1", "i2", "i3", "i4"].map(makeInteractionItem(id:)),
                fetchedCount: 5
            )
        }
        return NotificationPage(items: [makeInteractionItem(id: "i5")], fetchedCount: 1)
    }

    func fetchInteractionUnreadCount() async throws -> Int { 1 }
    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem {
        AnnouncementDetailItem(id: id, title: "t", content: "c", createdAt: "now")
    }
    func fetchFestival() async throws -> Festival? { nil }
    func markNotificationRead(notificationID: String) async throws {}
    func markAllNotificationsRead() async throws {}

    private func makeAnnouncementItem(id: String) -> AppNotificationItem {
        AppNotificationItem(
            id: id,
            category: .system,
            module: nil,
            title: id,
            message: id,
            createdAt: "now",
            isRead: false,
            destination: .announcement,
            targetType: nil,
            targetID: id,
            targetSubID: nil
        )
    }

    private func makeInteractionItem(id: String) -> AppNotificationItem {
        AppNotificationItem(
            id: id,
            category: .comment,
            module: "topic",
            title: id,
            message: id,
            createdAt: "now",
            isRead: false,
            destination: .topic,
            targetType: nil,
            targetID: id,
            targetSubID: nil
        )
    }
}
