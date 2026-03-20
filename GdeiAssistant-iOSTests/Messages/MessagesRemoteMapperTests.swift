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
        XCTAssertEqual(mapped.title, "卖室友")
        XCTAssertEqual(mapped.message, "你有一条新的互动消息")
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
        XCTAssertEqual(mapped[0].title, "系统公告")
        XCTAssertEqual(mapped[0].message, "暂无公告内容")
        XCTAssertEqual(mapped[0].createdAt, "刚刚")
        XCTAssertNil(mapped[0].destination)
    }
}
