import XCTest
@testable import GdeiAssistant_iOS

final class ProfileFormSupportTests: XCTestCase {
    func testMajorOptionsFollowSelectedFaculty() {
        XCTAssertEqual(
            ProfileFormSupport.defaultOptions.majorOptions(for: "计算机科学系"),
            ["未选择", "软件工程", "网络工程", "计算机科学与技术", "物联网工程"]
        )
        XCTAssertEqual(ProfileFormSupport.defaultOptions.majorOptions(for: "不存在的院系"), ["未选择"])
    }

    func testLocationDisplayDeduplicatesAdjacentSegments() {
        XCTAssertEqual(
            ProfileFormSupport.makeLocationDisplay(region: "中国", state: "广东", city: "广东"),
            "中国 广东"
        )
        XCTAssertEqual(
            ProfileFormSupport.makeLocationDisplay(region: "中国", state: "广东", city: "广州"),
            "中国 广东 广州"
        )
    }
}
