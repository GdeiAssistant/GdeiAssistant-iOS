import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MarketplaceViewModelTests: XCTestCase {

    func testInitialStateIsEmpty() {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())

        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
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
}
