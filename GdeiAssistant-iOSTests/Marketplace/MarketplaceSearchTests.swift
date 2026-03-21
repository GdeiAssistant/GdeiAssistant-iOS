import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MarketplaceSearchTests: XCTestCase {

    func testSearchUpdatesItems() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())
        await vm.loadIfNeeded()
        let allCount = vm.items.count

        vm.searchQuery = "测试"
        await vm.search()

        XCTAssertNotNil(vm.items)
        XCTAssertFalse(vm.isLoading)
    }

    func testClearSearchRestoresAllItems() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())
        await vm.loadIfNeeded()
        let allCount = vm.items.count

        vm.searchQuery = "nonexistent"
        await vm.search()

        await vm.clearSearch()
        XCTAssertTrue(vm.searchQuery.isEmpty)
        XCTAssertEqual(vm.items.count, allCount)
    }

    func testSearchClearsTypeSelection() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())
        await vm.loadIfNeeded()

        vm.selectedTypeID = 1
        vm.searchQuery = "笔记本"
        await vm.search()

        XCTAssertNil(vm.selectedTypeID)
    }

    func testEmptySearchQueryLoadsAllItems() async {
        let vm = MarketplaceViewModel(repository: MockMarketplaceRepository())
        await vm.loadIfNeeded()
        let allCount = vm.items.count

        vm.searchQuery = ""
        await vm.refresh()

        XCTAssertEqual(vm.items.count, allCount)
    }
}
