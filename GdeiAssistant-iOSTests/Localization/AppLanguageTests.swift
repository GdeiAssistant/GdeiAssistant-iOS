import XCTest
@testable import GdeiAssistant_iOS

final class AppLanguageTests: XCTestCase {
    func testNormalizePreservesSupportedLocaleIdentifiers() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-CN"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-HK"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-TW"), "zh-TW")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "en"), "en")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ja"), "ja")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ko"), "ko")
    }

    func testNativeNamesSeparateHongKongMacauAndTaiwanTraditionalChinese() {
        XCTAssertEqual(AppLanguage.traditionalChineseHongKong.nativeName, "繁體中文（港澳）")
        XCTAssertEqual(AppLanguage.traditionalChineseTaiwan.nativeName, "繁體中文（台灣）")
        XCTAssertFalse(AppLanguage.allCases.map(\.nativeName).contains("繁體中文（香港）"))
    }

    func testNormalizeMapsLocaleVariantsToSupportedIdentifiers() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans-CN"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans-SG"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-HK"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-TW"), "zh-TW")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-MO"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-MO"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "en-US"), "en")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ja-JP"), "ja")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ko-KR"), "ko")
    }

    func testNormalizeFallsBackToSimplifiedChineseForUnsupportedIdentifiers() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "fr-FR"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "de"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: ""), "zh-CN")
    }

    func testNormalizeHandlesCaseWhitespaceAndUnderscore() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ZH-CN"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "  zh-TW  "), "zh-TW")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh_HK"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh_Hans_CN"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "EN-us"), "en")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ja_JP"), "ja")
    }

    func testNormalizeAcceptLanguageQualityAndCommaListUsesFirstItemOnly() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-HK;q=0.9"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-CN;q=1"), "zh-CN")
        // Unsupported first Accept-Language item must not peek at later tags.
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "fr-FR,zh-CN;q=0.8"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "de;q=0.7,en;q=0.6"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: ",en;q=0.6"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: ";q=0.7,en;q=0.6"), "zh-CN")
    }

    func testDetectSystemLanguageUsesFirstSupportedPreferredLanguage() {
        XCTAssertEqual(
            AppLanguage.detectSystemLanguage(fromPreferredLanguages: ["fr-FR", "zh-Hant-HK"]),
            "zh-HK"
        )
        XCTAssertEqual(
            AppLanguage.detectSystemLanguage(fromPreferredLanguages: ["en-US", "ja-JP"]),
            "en"
        )
        // Preferred-language list still walks entries; only in-entry Accept-Language commas are stripped.
        XCTAssertEqual(
            AppLanguage.detectSystemLanguage(fromPreferredLanguages: ["fr-FR;q=0.8", "zh_TW"]),
            "zh-TW"
        )
    }

    func testDetectSystemLanguageFallsBackToSimplifiedChinese() {
        XCTAssertEqual(
            AppLanguage.detectSystemLanguage(fromPreferredLanguages: ["fr-FR", "de-DE"]),
            "zh-CN"
        )
        XCTAssertEqual(
            AppLanguage.detectSystemLanguage(fromPreferredLanguages: []),
            "zh-CN"
        )
    }

    @MainActor
    func testEverySupportedLanguageHasCompleteResourcesAndMatchingFormatArguments() throws {
        let baseline = try resourceTable(for: .simplifiedChinese)
        let baselineCatalog = try XCTUnwrap(LocalizedProfileCatalog.localizedLabels["zh-CN"])
        XCTAssertGreaterThan(baseline.count, 1700)
        for language in AppLanguage.allCases {
            let table = try resourceTable(for: language)
            let catalog = try XCTUnwrap(LocalizedProfileCatalog.localizedLabels[language.localeIdentifier])
            XCTAssertEqual(Set(catalog.keys), Set(baselineCatalog.keys), language.rawValue)
            XCTAssertFalse(catalog.values.contains(where: { $0.isEmpty }))
            XCTAssertEqual(Set(table.keys), Set(baseline.keys), language.rawValue)
            XCTAssertFalse(table.values.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
            for (key, value) in table {
                XCTAssertEqual(try formatArguments(value), try formatArguments(baseline[key] ?? ""), "\(language.rawValue): \(key)")
            }
            let permissions = try resourceTable(for: language, name: "InfoPlist")
            XCTAssertEqual(Set(permissions.keys), Set(["NSMicrophoneUsageDescription"]))
            XCTAssertFalse(permissions["NSMicrophoneUsageDescription"]?.isEmpty ?? true)
        }
    }

    @MainActor
    func testInitialDetectedLanguageIsPersistedAndStoredVariantsAreNormalized() throws {
        let suite = "gdeiassistant.locale.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let initial = UserPreferences(defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedLocale), initial.selectedLocale)
        defaults.set(" ZH_hAnT_MO ;q=0.9,en;q=0.8", forKey: AppConstants.UserDefaultsKeys.selectedLocale)
        let restored = UserPreferences(defaults: defaults)
        XCTAssertEqual(restored.selectedLocale, "zh-HK")
        XCTAssertEqual(AppLanguage.currentIdentifier(defaults: defaults), "zh-HK")
    }

    @MainActor
    func testLanguageSwitchUpdatesDefaultLookupAndPreservesProfileDraft() {
        let defaults = UserDefaults.standard
        let key = AppConstants.UserDefaultsKeys.selectedLocale
        let previous = defaults.object(forKey: key)
        defer { defaults.set(previous, forKey: key) }
        let preferences = UserPreferences(defaults: defaults)
        let session = SessionState()
        let profile = ProfileViewModel(repository: MockProfileRepository(), sessionState: session)
        profile.nickname = "小明 / Alice"
        profile.bio = "我寫嘅內容不翻譯"
        let expected = [
            "zh-CN": "隐私设置", "zh-HK": "私隱設定", "zh-TW": "隱私權設定",
            "en": "Privacy Settings", "ja": "プライバシー設定", "ko": "개인정보 설정"
        ]
        for language in AppLanguage.allCases {
            preferences.selectedLocale = language.localeIdentifier
            XCTAssertEqual(AppLanguage.currentIdentifier(), language.localeIdentifier)
            XCTAssertEqual(localizedString("privacy.title"), expected[language.localeIdentifier])
            XCTAssertEqual(profile.nickname, "小明 / Alice")
            XCTAssertEqual(profile.bio, "我寫嘅內容不翻譯")
        }
    }

    @MainActor
    func testDeliverySubmissionLocalizesGeneratedTitleAndKeepsUserContent() async throws {
        let defaults = UserDefaults.standard
        let key = AppConstants.UserDefaultsKeys.selectedLocale
        let previous = defaults.object(forKey: key)
        defer { defaults.set(previous, forKey: key) }
        let preferences = UserPreferences(defaults: defaults)
        preferences.selectedLocale = "en"
        let repository = MockDeliveryRepository()
        let viewModel = PublishDeliveryViewModel(repository: repository)
        viewModel.pickupPlace = "菜鸟驿站"
        viewModel.phone = "13800138000"
        viewModel.address = "南苑 3 棟"
        viewModel.rewardText = "2.50"
        viewModel.remarks = "放門口 / leave at door"
        let didSubmit = await viewModel.submit()
        XCTAssertTrue(didSubmit)
        let orders = try await repository.fetchOrders(start: 0, size: 1)
        let order = try XCTUnwrap(orders.first)
        XCTAssertEqual(order.name, "Pickup")
        XCTAssertEqual(order.company, "菜鸟驿站")
        XCTAssertEqual(order.address, "南苑 3 棟")
        XCTAssertEqual(order.remarks, "放門口 / leave at door")
        XCTAssertEqual(order.state, .pending)
        XCTAssertEqual(order.price, 2.50)
    }

    @MainActor
    func testChatDateUsesAppLanguageInsteadOfDeviceLanguage() {
        let defaults = UserDefaults.standard
        let key = AppConstants.UserDefaultsKeys.selectedLocale
        let previous = defaults.object(forKey: key)
        defer { defaults.set(previous, forKey: key) }
        let preferences = UserPreferences(defaults: defaults)
        preferences.selectedLocale = "en"
        let english = SocialDisplayTime.format("2000-01-02T12:00:00+08:00")
        XCTAssertTrue(english.contains("Jan"), english)
        preferences.selectedLocale = "ja"
        let japanese = SocialDisplayTime.format("2000-01-02T12:00:00+08:00")
        XCTAssertTrue(japanese.contains("2000"), japanese)
        XCTAssertFalse(japanese.contains("Jan"), japanese)
        XCTAssertNotEqual(english, japanese)
        XCTAssertEqual(SocialDisplayTime.format("user-supplied time"), "user-supplied time")
    }

    private func resourceTable(for language: AppLanguage, name: String = "Localizable") throws -> [String: String] {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language.lprojResourceName, ofType: "lproj"))
        let url = URL(fileURLWithPath: path).appendingPathComponent("\(name).strings")
        let data = try Data(contentsOf: url)
        let dictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(dictionary as? [String: String])
    }

    private func formatArguments(_ value: String) throws -> [String] {
        let expression = try NSRegularExpression(pattern: #"%(?:\d+\$)?[-+ #0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hlLzjtq])?[@diuoxXfFeEgGaAcCsSp%]"#)
        return expression.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap { match in
            guard let range = Range(match.range, in: value) else { return nil }
            let argument = String(value[range])
            return argument == "%%" ? nil : argument
        }.sorted()
    }
}
