import XCTest

final class MockRuntimePerformanceTests: XCTestCase {
    private var appUnderTest: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        appUnderTest?.terminate()
        appUnderTest = nil
    }

    func testLaunchToResponsiveHomeBaseline() throws {
        let app = makeMockHomeApp()
        let options = XCTMeasureOptions()
        options.iterationCount = 5

        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)], options: options) {
            app.launch()
        }

        XCTAssertTrue(app.buttons["home.entry.grade"].waitForExistence(timeout: 10))
        attachScreenshot(app, name: "runtime-baseline-responsive-home")
    }

    func testScrollAllFunctionsBaseline() throws {
        let app = makeMockHomeApp()
        app.launch()
        XCTAssertTrue(app.buttons["home.entry.grade"].waitForExistence(timeout: 10))
        let allFunctions = app.buttons["home.allFunctions"]
        for _ in 0..<6 where !allFunctions.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(allFunctions.isHittable)
        allFunctions.tap()
        XCTAssertTrue(app.navigationBars["全部功能"].waitForExistence(timeout: 10))

        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart]
        let firstEntry = app.buttons["home.entry.grade"]
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric, XCTClockMetric()], options: options) {
            // Reset outside the measured interval so every sample scrolls the same existing list.
            for _ in 0..<4 where !firstEntry.isHittable {
                app.swipeDown(velocity: .fast)
            }
            XCTAssertTrue(firstEntry.isHittable)
            startMeasuring()
            app.swipeUp(velocity: .fast)
            app.swipeUp(velocity: .fast)
            stopMeasuring()
            XCTAssertFalse(firstEntry.isHittable, "The measured gestures must move the list")
        }
        attachScreenshot(app, name: "runtime-baseline-all-functions-scrolled")
    }

    private func makeMockHomeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GDEIASSISTANT_RUNNING_TESTS"] = "1"
        app.launchEnvironment["GDEI_UI_USE_MOCK"] = "1"
        app.launchEnvironment["GDEI_UI_LOCALE"] = "zh-Hans"
        app.launchEnvironment["GDEI_UI_APPEARANCE"] = "light"
        app.launchEnvironment["GDEI_UI_AUTHENTICATED"] = "1"
        app.launchEnvironment["GDEI_UI_INITIAL_SCREEN"] = "home"
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh-Hans", "-font_scale_step", "1"]
        appUnderTest = app
        return app
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
