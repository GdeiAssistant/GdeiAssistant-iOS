import XCTest

final class MockUISmokeTests: XCTestCase {
    private enum InitialScreen: String {
        case home
        case messages
        case marketplace
        case grade
        case conversations
    }

    private var appUnderTest: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let app = appUnderTest, let run = testRun, !run.hasSucceeded {
            attachScreenshot(app, name: "failure-screen")
            attachHierarchy(app, name: "failure-accessibility-tree")
        }
        appUnderTest = nil
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

    func testChatSystemPhotoPickerPreviewRemoveSendViewAndLeaveCleanup() throws {
        let app = launchApp(authenticated: true, initialScreen: .conversations)
        openMockChat(app)

        selectPhotoUsingSystemPicker(app)
        attachScreenshot(app, name: "chat-selected-photo-preview")
        XCTAssertTrue(app.buttons["social.chat.send"].isEnabled)
        app.buttons["social.chat.removeImage"].tap()
        waitForDisappearance(app.images["social.chat.draftImage"])
        XCTAssertFalse(app.buttons["social.chat.send"].isEnabled)
        XCTAssertEqual(ownImageButtons(app).count, 0)

        selectPhotoUsingSystemPicker(app)
        app.buttons["social.chat.send"].tap()
        let sentImage = ownImageButtons(app).firstMatch
        XCTAssertTrue(sentImage.waitForExistence(timeout: 10))
        let clientID = clientMessageID(from: sentImage)
        waitForDelivery(app, clientID: clientID, label: "已发送")
        XCTAssertEqual(sentImage.value as? String, "480 × 320")
        XCTAssertEqual(ownImageButtons(app).count, 1)
        XCTAssertFalse(app.images["social.chat.draftImage"].exists)
        attachScreenshot(app, name: "chat-image-sent")
        verifyImageViewer(app, imageButton: sentImage, name: "chat-sent-image-viewer")

        // Leave an actual picker-produced draft, then use the native Back action.
        selectPhotoUsingSystemPicker(app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        openMockChat(app)
        XCTAssertFalse(app.images["social.chat.draftImage"].exists)
        XCTAssertFalse(app.buttons["social.chat.send"].isEnabled)
        XCTAssertEqual(ownImageButtons(app).count, 1, "Committed history survives; the draft is cleared")
        attachScreenshot(app, name: "chat-draft-cleared-after-return")
    }

    func testChatSystemPhotoPickerFailedImageRetryKeepsOneMessage() throws {
        let app = launchApp(
            authenticated: true, initialScreen: .conversations, failFirstImageSend: true
        )
        openMockChat(app)
        selectPhotoUsingSystemPicker(app)
        sendImageExpectingFailure(app)

        let failedImage = ownImageButtons(app).firstMatch
        let originalImageIdentifier = failedImage.identifier
        let clientID = clientMessageID(from: failedImage)
        waitForDelivery(app, clientID: clientID, label: "失败")
        attachScreenshot(app, name: "chat-image-send-failed")
        verifyImageViewer(app, imageButton: failedImage, name: "chat-failed-local-image-viewer")

        let retry = app.buttons["social.chat.retry.\(clientID)"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        retry.tap()
        waitForDelivery(app, clientID: clientID, label: "已发送")
        XCTAssertTrue(app.buttons[originalImageIdentifier].exists, "Retry retains the original clientMessageId")
        XCTAssertEqual(ownImageButtons(app).count, 1, "Retry must replace the failed bubble")
        XCTAssertFalse(retry.exists)
        verifyImageViewer(app, imageButton: ownImageButtons(app).firstMatch, name: "chat-retried-image-viewer")
        attachScreenshot(app, name: "chat-image-retry-succeeded")
    }

    func testChatLogoutClearsPickerDraftAndFailedLocalImage() throws {
        let app = launchApp(
            authenticated: true, initialScreen: .conversations, failFirstImageSend: true
        )
        openMockChat(app)
        selectPhotoUsingSystemPicker(app)
        sendImageExpectingFailure(app)
        let failedClientID = clientMessageID(from: ownImageButtons(app).firstMatch)
        waitForDelivery(app, clientID: failedClientID, label: "失败")
        selectPhotoUsingSystemPicker(app)
        attachScreenshot(app, name: "chat-failed-message-and-unsent-draft-before-logout")

        // This test-only shortcut calls the normal AuthManager.logout/session cleanup.
        app.buttons["social.chat.testLogout"].tap()
        XCTAssertTrue(app.textFields["login.username"].waitForExistence(timeout: 10))
        loginAsMockUser(app, expectedEntry: "social.conversation.1")
        openMockChat(app)
        XCTAssertFalse(app.images["social.chat.draftImage"].exists)
        XCTAssertEqual(ownImageButtons(app).count, 0)
        XCTAssertFalse(app.buttons["social.chat.retry.\(failedClientID)"].exists)
        XCTAssertFalse(app.buttons["social.chat.send"].isEnabled)
        attachScreenshot(app, name: "chat-local-images-cleared-after-logout-and-login")
    }

    private func openMockChat(_ app: XCUIApplication) {
        let conversation = app.buttons["social.conversation.1"]
        XCTAssertTrue(conversation.waitForExistence(timeout: 10))
        conversation.tap()
        XCTAssertTrue(app.buttons["social.chat.pickImage"].waitForExistence(timeout: 10))
    }

    private func selectPhotoUsingSystemPicker(_ app: XCUIApplication) {
        let picker = app.buttons["social.chat.pickImage"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        // The iOS 26.2 system picker exposes thumbnails as Images, not Cells.
        // Scope the observed grid identifier to the system Photos scroll view so
        // icons/underlying chat images cannot match. CI imports the newest photo.
        let firstPhoto = app.scrollViews["photosView_content_scroll_view"]
            .images.matching(identifier: "PXGGridLayout-Info").firstMatch
        let photoExists = firstPhoto.waitForExistence(timeout: 20)
        attachScreenshot(app, name: "system-photos-picker")
        attachHierarchy(app, name: "system-photos-picker-accessibility-tree")
        XCTAssertTrue(
            photoExists,
            "System PhotosPicker must expose the seeded image in its photo grid."
        )
        // Photos renders this visible thumbnail as a virtual AX Image whose
        // automatic hit point is {-1, -1}. Send a real touch at its live center.
        let photoFrame = firstPhoto.frame
        let window = app.windows.firstMatch
        let windowFrame = window.frame
        XCTAssertFalse(photoFrame.isEmpty)
        XCTAssertTrue(windowFrame.contains(photoFrame), "The seeded photo must be visible on screen")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: photoFrame.midX - windowFrame.minX, dy: photoFrame.midY - windowFrame.minY))
            .tap()
        let preview = app.images["social.chat.draftImage"]
        if !preview.waitForExistence(timeout: 5) {
            // Some picker versions use an explicit confirmation for a single selection.
            let confirm = app.buttons.matching(
                NSPredicate(format: "label IN %@", ["添加", "完成", "Add", "Done"])
            ).firstMatch
            if confirm.exists { confirm.tap() }
        }
        XCTAssertTrue(preview.waitForExistence(timeout: 15), "Selected system photo must decode into a draft")
        XCTAssertEqual(preview.value as? String, "480 × 320", "Select the seeded synthetic photo")
        XCTAssertTrue(app.buttons["social.chat.removeImage"].exists)
    }

    private func sendImageExpectingFailure(_ app: XCUIApplication) {
        app.buttons["social.chat.send"].tap()
        let notice = app.alerts.firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 10))
        attachScreenshot(app, name: "chat-image-failure-alert")
        notice.buttons["知道了"].tap()
        XCTAssertTrue(ownImageButtons(app).firstMatch.waitForExistence(timeout: 5))
    }

    private func verifyImageViewer(_ app: XCUIApplication, imageButton: XCUIElement, name: String) {
        imageButton.tap()
        XCTAssertTrue(app.buttons["social.chat.viewer.close"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["social.chat.viewer.image"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.images["social.chat.viewer.image"].value as? String, "480 × 320")
        attachScreenshot(app, name: name)
        app.buttons["social.chat.viewer.close"].tap()
        waitForDisappearance(app.buttons["social.chat.viewer.close"])
    }

    private func ownImageButtons(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "social.chat.image.mine."))
    }

    private func clientMessageID(from imageButton: XCUIElement) -> String {
        String(imageButton.identifier.dropFirst("social.chat.image.mine.".count))
    }

    private func waitForDelivery(_ app: XCUIApplication, clientID: String, label: String) {
        let delivery = app.staticTexts["social.chat.delivery.\(clientID)"]
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label == %@", label), object: delivery
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed)
    }

    private func waitForDisappearance(_ element: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachHierarchy(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @discardableResult
    private func launchApp(
        authenticated: Bool = false,
        initialScreen: InitialScreen? = nil,
        failFirstImageSend: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GDEIASSISTANT_RUNNING_TESTS"] = "1"
        app.launchEnvironment["GDEI_UI_USE_MOCK"] = "1"
        app.launchEnvironment["GDEI_UI_LOCALE"] = "zh-Hans"
        if failFirstImageSend {
            app.launchEnvironment["GDEI_UI_FAIL_FIRST_CHAT_IMAGE"] = "1"
        }
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
        appUnderTest = app
        app.launch()
        return app
    }

    private func loginAsMockUser(_ app: XCUIApplication, expectedEntry: String = "home.entry.grade") {
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

        XCTAssertTrue(app.buttons[expectedEntry].waitForExistence(timeout: 20))
    }
}
