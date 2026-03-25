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

    func testNormalizeMapsLocaleVariantsToSupportedIdentifiers() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans-CN"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hans-SG"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-HK"), "zh-HK")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-TW"), "zh-TW")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "zh-Hant-MO"), "zh-TW")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "en-US"), "en")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ja-JP"), "ja")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "ko-KR"), "ko")
    }

    func testNormalizeFallsBackToSimplifiedChineseForUnsupportedIdentifiers() {
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "fr-FR"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: "de"), "zh-CN")
        XCTAssertEqual(AppLanguage.normalizedIdentifier(from: ""), "zh-CN")
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
}
