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
}
