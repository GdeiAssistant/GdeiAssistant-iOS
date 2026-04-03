import XCTest

final class MockUISmokeTests: XCTestCase {
    private enum InitialScreen: String {
        case home
        case messages
        case marketplace
        case grade
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMockLoginShowsHomeEntries() throws {
        let app = launchApp()

        loginAsMockUser(app)

        XCTAssertTrue(app.buttons["home.entry.grade"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.entry.marketplace"].exists)
    }

    func testMockMessagesTabShowsAnnouncementsAndInteractions() throws {
        let app = launchApp(authenticated: true, initialScreen: .messages)

        XCTAssertTrue(app.staticTexts["messages.section.news"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["messages.section.system"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["messages.section.interaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["messages.interaction.msg_interaction_001"].waitForExistence(timeout: 5))
    }

    func testMockMarketplaceFlowShowsDetailAndPublishEntry() throws {
        let app = launchApp(authenticated: true, initialScreen: .marketplace)

        XCTAssertTrue(app.buttons["marketplace.item.market_001"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["marketplace.publishEntry"].waitForExistence(timeout: 5))

        app.buttons["marketplace.item.market_001"].tap()

        XCTAssertTrue(app.staticTexts["marketplace.detail.description"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["marketplace.publishEntry"].waitForExistence(timeout: 5))
        app.buttons["marketplace.publishEntry"].tap()

        XCTAssertTrue(app.staticTexts["marketplace.publish.images"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["marketplace.publish.submit"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["marketplace.publish.submit"].isEnabled)
    }

    func testMockGradeEntryLoadsAcademicContent() throws {
        let app = launchApp(authenticated: true, initialScreen: .grade)

        XCTAssertTrue(app.segmentedControls["grade.yearPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["grade.course.grade_2526_01"].waitForExistence(timeout: 5))
    }

    @discardableResult
    private func launchApp(
        authenticated: Bool = false,
        initialScreen: InitialScreen? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GDEIASSISTANT_RUNNING_TESTS"] = "1"
        app.launchEnvironment["GDEI_UI_USE_MOCK"] = "1"
        app.launchEnvironment["GDEI_UI_LOCALE"] = "zh-Hans"
        if authenticated {
            app.launchEnvironment["GDEI_UI_AUTHENTICATED"] = "1"
        }
        if let initialScreen {
            app.launchEnvironment["GDEI_UI_INITIAL_SCREEN"] = initialScreen.rawValue
        }
        app.launchArguments += [
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh-Hans"
        ]
        app.launch()
        return app
    }

    private func loginAsMockUser(_ app: XCUIApplication) {
        let usernameField = app.textFields["login.username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.tap()
        usernameField.typeText("gdeiassistant")

        let passwordField = app.secureTextFields["login.password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("gdeiassistant")

        let submitButton = app.buttons["login.submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()

        XCTAssertTrue(app.buttons["home.entry.grade"].waitForExistence(timeout: 20))
    }
}
