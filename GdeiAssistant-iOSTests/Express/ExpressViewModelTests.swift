import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class ExpressViewModelTests: XCTestCase {

    func testSubmitFailsWithEmptyNickname() async {
        let vm = PublishExpressViewModel(repository: MockExpressRepository())
        vm.nickname = ""
        vm.targetName = "小红"
        vm.content = "表白内容"

        let success = await vm.submit()

        XCTAssertFalse(success)
        if case .failure(let message) = vm.submitState {
            XCTAssertTrue(message.contains("昵称"))
        } else {
            XCTFail("Expected failure state")
        }
    }

    func testSubmitFailsWithNicknameOver10Chars() async {
        let vm = PublishExpressViewModel(repository: MockExpressRepository())
        vm.nickname = String(repeating: "a", count: 11)
        vm.targetName = "小红"
        vm.content = "表白内容"

        let success = await vm.submit()

        XCTAssertFalse(success)
        if case .failure(let message) = vm.submitState {
            XCTAssertTrue(message.contains("10"))
        } else {
            XCTFail("Expected failure state")
        }
    }

    func testSubmitFailsWithEmptyTargetName() async {
        let vm = PublishExpressViewModel(repository: MockExpressRepository())
        vm.nickname = "小明"
        vm.targetName = ""
        vm.content = "表白内容"

        let success = await vm.submit()

        XCTAssertFalse(success)
        if case .failure(let message) = vm.submitState {
            XCTAssertTrue(message.contains("名字") || message.contains("TA"))
        } else {
            XCTFail("Expected failure state")
        }
    }

    func testSubmitFailsWithContentOver250Chars() async {
        let vm = PublishExpressViewModel(repository: MockExpressRepository())
        vm.nickname = "小明"
        vm.targetName = "小红"
        vm.content = String(repeating: "x", count: 251)

        let success = await vm.submit()

        XCTAssertFalse(success)
        if case .failure(let message) = vm.submitState {
            XCTAssertTrue(message.contains("250"))
        } else {
            XCTFail("Expected failure state")
        }
    }

    func testSubmitSucceedsWithValidInput() async {
        let vm = PublishExpressViewModel(repository: MockExpressRepository())
        vm.nickname = "小明"
        vm.targetName = "小红"
        vm.content = "你好"

        let success = await vm.submit()

        XCTAssertTrue(success)
    }
}
