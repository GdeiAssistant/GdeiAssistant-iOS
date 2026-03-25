import XCTest
@testable import GdeiAssistant_iOS

final class MessagesRemoteMapperTests: XCTestCase {
    func testMapInteractionItemsNormalizesKnownModuleAliasesCaseInsensitively() throws {
        let item = InteractionNotificationRemoteDTO(
            id: nil,
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

    func testMapAnnouncementItemsUsesFallbacksAndDropsDestinationWithoutID() {
        let item = AnnouncementRemoteDTO(
            id: "  ",
            title: nil,
            content: nil,
            publishTime: nil
        )

        let mapped = MessagesRemoteMapper.mapAnnouncementItems([item])

        XCTAssertEqual(mapped.count, 1)
        XCTAssertEqual(mapped[0].category, .system)
        XCTAssertEqual(mapped[0].title, localizedString("messages.mapper.announcementTitle"))
        XCTAssertEqual(mapped[0].message, localizedString("messages.mapper.announcementEmptyContent"))
        XCTAssertEqual(mapped[0].createdAt, localizedString("common.justNow"))
        XCTAssertNil(mapped[0].destination)
    }
}
