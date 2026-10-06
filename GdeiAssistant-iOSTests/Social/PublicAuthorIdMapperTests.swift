import XCTest
@testable import GdeiAssistant_iOS

final class PublicAuthorIdMapperTests: XCTestCase {
    func testMarketplaceDetailPreservesAuthorIdAndAvatarPath() throws {
        let dto = MarketplaceDetailDTO(
            ownedByCurrentUser: false,
            profile: MarketplaceProfileDTO(
                avatarURL: "/api/social/users/user-seller-1/avatar",
                displayName: "seller",
                nickname: "卖家甲",
                faculty: nil,
                enrollment: nil,
                major: nil
            ),
            item: MarketplaceItemDTO(
                id: 11,
                displayName: "seller",
                authorId: " user-seller-1 ",
                name: "二手书",
                description: "几乎全新",
                price: RemoteFlexibleString("12.5"),
                location: "海珠",
                type: 0,
                qq: nil,
                phone: nil,
                state: 1,
                publishTime: RemoteFlexibleString("2026-10-05T12:00:00+08:00"),
                pictureURL: ["https://cdn.example.com/item.png"]
            )
        )

        let detail = try MarketplaceRemoteMapper.mapDetail(dto)
        XCTAssertEqual(detail.item.authorId, "user-seller-1")
        XCTAssertEqual(detail.item.sellerAvatarURL, "/api/social/users/user-seller-1/avatar")
        XCTAssertEqual(detail.imageURLs, ["https://cdn.example.com/item.png"])
    }

    func testMarketplaceDetailOmitsBlankAuthorId() throws {
        let dto = MarketplaceDetailDTO(
            ownedByCurrentUser: false,
            profile: nil,
            item: MarketplaceItemDTO(
                id: 12,
                displayName: "seller",
                authorId: "   ",
                name: "风扇",
                description: "能用",
                price: RemoteFlexibleString("20"),
                location: "北苑",
                type: 0,
                qq: nil,
                phone: nil,
                state: 1,
                publishTime: nil,
                pictureURL: nil
            )
        )

        let detail = try MarketplaceRemoteMapper.mapDetail(dto)
        XCTAssertNil(detail.item.authorId)
    }

    func testLostFoundDetailPreservesAuthorId() throws {
        let dto = LostFoundDetailDTO(
            item: LostFoundItemDTO(
                id: 3,
                username: "finder",
                authorId: "user-lost-3",
                name: "校园卡",
                description: "一卡通",
                location: "食堂",
                itemType: 1,
                lostType: 1,
                qq: nil,
                wechat: nil,
                phone: nil,
                state: 0,
                publishTime: nil,
                pictureURL: nil
            ),
            profile: LostFoundProfileDTO(
                avatarURL: "/api/social/users/user-lost-3/avatar",
                username: "finder",
                nickname: "拾主"
            )
        )

        let detail = try LostFoundRemoteMapper.mapDetail(dto)
        XCTAssertEqual(detail.authorId, "user-lost-3")
        XCTAssertEqual(detail.ownerAvatarURL, "/api/social/users/user-lost-3/avatar")
    }

    func testPhotographAndTopicPreserveOrOmitAuthorId() {
        let photo = PhotographRemoteMapper.mapPost(
            PhotographRemoteDTO(
                id: RemoteFlexibleString("p1"),
                title: "雨后",
                content: "教学楼",
                count: RemoteFlexibleString("1"),
                type: RemoteFlexibleString("0"),
                username: "摄影社",
                authorId: "user-photo-1",
                createTime: nil,
                likeCount: nil,
                commentCount: nil,
                liked: nil,
                firstImageUrl: nil,
                imageUrls: nil,
                photographCommentList: nil
            )
        )
        XCTAssertEqual(photo.authorId, "user-photo-1")

        let topicWithout = TopicRemoteMapper.mapPost(
            TopicRemoteDTO(
                id: RemoteFlexibleString("t1"),
                username: "同学",
                authorId: nil,
                topic: "求助",
                content: "有没有人一起学习",
                count: nil,
                publishTime: nil,
                likeCount: nil,
                liked: nil,
                firstImageUrl: nil,
                imageUrls: nil
            )
        )
        XCTAssertNil(topicWithout.authorId)
    }

    func testDatingAuthorIdIsPublisherOnly() {
        let mapped = DatingRemoteMapper.mapProfile(
            DatingProfileDTO(
                profileId: 9,
                username: nil,
                authorId: "user-publisher-9",
                nickname: "被介绍的室友昵称",
                grade: 2,
                faculty: "外语系",
                hometown: "广州",
                content: "介绍室友",
                qq: nil,
                wechat: nil,
                area: 0,
                state: 1,
                pictureURL: "https://cdn.example.com/roommate.jpg"
            )
        )

        XCTAssertEqual(mapped.nickname, "被介绍的室友昵称")
        XCTAssertEqual(mapped.authorId, "user-publisher-9")
        XCTAssertEqual(mapped.imageURL, "https://cdn.example.com/roommate.jpg")
    }
}
