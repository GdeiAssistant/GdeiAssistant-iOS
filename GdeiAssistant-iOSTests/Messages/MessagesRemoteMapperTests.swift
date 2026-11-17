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
}
