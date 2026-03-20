import XCTest
@testable import GdeiAssistant_iOS

final class DatingRemoteMapperTests: XCTestCase {
    func testMapProfileDetailPreservesContactVisibilityAndArea() {
        let detail = DatingProfileDetailDTO(
            profile: DatingProfileDTO(
                profileId: 8,
                username: "alice",
                nickname: "阿离",
                grade: 2,
                faculty: "计算机科学系",
                hometown: "广州",
                content: "会做饭会拍照",
                qq: "123456",
                wechat: "alice-wechat",
                area: 1,
                state: 1,
                pictureURL: "https://example.com/profile.jpg"
            ),
            pictureURL: "https://example.com/detail.jpg",
            isContactVisible: true,
            isPickNotAvailable: false
        )

        let mapped = DatingRemoteMapper.mapProfileDetail(detail)

        XCTAssertEqual(mapped.id, "8")
        XCTAssertEqual(mapped.profile.nickname, "阿离")
        XCTAssertEqual(mapped.profile.headline, "大二 · 计算机科学系")
        XCTAssertEqual(mapped.profile.hometown, "广州")
        XCTAssertEqual(mapped.profile.area, .boy)
        XCTAssertEqual(mapped.profile.imageURL, "https://example.com/detail.jpg")
        XCTAssertTrue(mapped.profile.isContactVisible)
        XCTAssertFalse(mapped.isPickNotAvailable)
    }

    func testMapSentPickKeepsAcceptedContactChannels() {
        let dto = DatingPickDTO(
            pickId: 5,
            roommateProfile: DatingProfileDTO(
                profileId: 9,
                username: nil,
                nickname: "学长",
                grade: 4,
                faculty: "外语系",
                hometown: "深圳",
                content: "爱运动",
                qq: "9988",
                wechat: "wechat-9988",
                area: 0,
                state: 1,
                pictureURL: "https://example.com/avatar.jpg"
            ),
            username: nil,
            content: "想认识一下",
            state: 1
        )

        let mapped = DatingRemoteMapper.mapSentPick(dto)

        XCTAssertEqual(mapped.id, "5")
        XCTAssertEqual(mapped.targetName, "学长")
        XCTAssertEqual(mapped.status, .accepted)
        XCTAssertEqual(mapped.targetQq, "9988")
        XCTAssertEqual(mapped.targetWechat, "wechat-9988")
    }
}
