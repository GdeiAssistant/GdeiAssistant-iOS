import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MarketplaceViewModelTests: XCTestCase {

    /// Sync construction used to crash the runner with
    /// `malloc: pointer being freed was not allocated` under
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (iOS 26.2 MainActor
    /// isolated-deinit back-deployment, swiftlang/swift#87316). The root
    /// fix is `nonisolated deinit` on `MarketplaceViewModel` and
    /// `MockMarketplaceRepository`; this sync case stays as a regression probe.
    func testInitialStateIsEmpty() {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())

        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testViewModelAndMockRepositoryReleaseSynchronouslyWithoutCrash() {
        for _ in 0..<20 {
            var vm: MarketplaceViewModel? = MarketplaceViewModel(
                repository: MockMarketplaceRepository()
            )
            weak var weakVM = vm
            vm = nil
            XCTAssertNil(weakVM)
        }
    }

    func testLoadIfNeededPopulatesItems() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())

        await vm.loadIfNeeded()

        XCTAssertFalse(vm.items.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadIfNeededSkipsWhenAlreadyLoaded() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())

        await vm.loadIfNeeded()
        let countAfterFirst = vm.items.count

        await vm.loadIfNeeded()
        XCTAssertEqual(vm.items.count, countAfterFirst)
    }

    func testEditMarketplaceViewModelReadsRawContactsAndTypeIDWithoutPrefixParsing() throws {
        let detail = MarketplaceDetail(
            item: MarketplaceItem(
                id: "market_edit_1",
                title: "二手耳机",
                price: 120,
                summary: "九成新",
                sellerName: "小明",
                sellerAvatarURL: nil,
                authorId: nil,
                postedAt: "刚刚",
                location: "海珠校区",
                state: .selling,
                tags: [],
                previewImageURL: nil,
                typeID: 4
            ),
            condition: "数码",
            description: "功能正常",
            contactHint: "已移除前缀解析",
            qq: "987654",
            phone: "13900139000",
            sellerUsername: nil,
            sellerNickname: nil,
            sellerCollege: nil,
            sellerMajor: nil,
            sellerGrade: nil,
            imageURLs: [],
            ownedByCurrentUser: true
        )

        let editVM = EditMarketplaceViewModel(detail: detail)

        XCTAssertEqual(editVM.selectedTypeID, 4)
        XCTAssertEqual(editVM.qq, "987654")
        XCTAssertEqual(editVM.phone, "13900139000")
        XCTAssertTrue(editVM.isFormValid)

        let draft = try XCTUnwrap(editVM.buildDraft())
        XCTAssertEqual(draft.typeID, 4)
        XCTAssertEqual(draft.qq, "987654")
        XCTAssertEqual(draft.phone, "13900139000")

        editVM.qq = "  "
        XCTAssertFalse(editVM.isFormValid)
        XCTAssertNil(editVM.buildDraft())
        XCTAssertNotNil(editVM.failureMessage)
    }
}
