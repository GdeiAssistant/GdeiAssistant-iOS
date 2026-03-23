import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class AppContainerBootstrapTests: XCTestCase {

    func testMockContainerBootstrapsWithoutCrash() async {
        let container = AppContainer.testing
        await container.bootstrapIfNeeded()

        // Assemblies are accessible
        XCTAssertNotNil(container.coreAssembly)
        XCTAssertNotNil(container.campusServicesAssembly)
        XCTAssertNotNil(container.communityAssembly)
        XCTAssertNotNil(container.profileAssembly)
    }

    func testMockContainerCanCreateSampleViewModels() async {
        let container = AppContainer.preview

        // Core — delegates to CoreAssembly
        let homeVM = container.makeHomeViewModel()
        XCTAssertNotNil(homeVM)

        // Campus services — delegates to CampusServicesAssembly
        let scheduleVM = container.makeScheduleViewModel()
        XCTAssertNotNil(scheduleVM)

        // Community — delegates to CommunityAssembly
        let communityVM = container.makeCommunityViewModel()
        XCTAssertNotNil(communityVM)

        // Profile — delegates to ProfileAssembly
        let settingsVM = container.makeSettingsViewModel()
        XCTAssertNotNil(settingsVM)
    }
}
