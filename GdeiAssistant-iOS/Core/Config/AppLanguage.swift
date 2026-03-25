import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-CN"
    case traditionalChineseHongKong = "zh-HK"
    case traditionalChineseTaiwan = "zh-TW"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    nonisolated var id: String { rawValue }

    nonisolated var localeIdentifier: String { rawValue }

    nonisolated var nativeName: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChineseHongKong:
            return "繁體中文（香港）"
        case .traditionalChineseTaiwan:
            return "繁體中文（台灣）"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }

    nonisolated var lprojResourceName: String {
        switch self {
        case .simplifiedChinese:
            return "zh-Hans"
        default:
            return rawValue
        }
    }

    nonisolated static var fallback: AppLanguage { .simplifiedChinese }

    nonisolated static var supportedLocaleIdentifiers: [String] {
        allCases.map(\.localeIdentifier)
    }

    nonisolated static func normalizedIdentifier(from identifier: String?) -> String {
        language(from: identifier)?.localeIdentifier ?? fallback.localeIdentifier
    }

    nonisolated static func detectSystemLanguage(
        fromPreferredLanguages preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        for identifier in preferredLanguages {
            if let language = language(from: identifier) {
                return language.localeIdentifier
            }
        }

        return fallback.localeIdentifier
    }

    nonisolated static func currentIdentifier(defaults: UserDefaults = .standard) -> String {
        let storedIdentifier = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedLocale)
        return normalizedIdentifier(from: storedIdentifier)
    }

    nonisolated static func locale(for identifier: String? = nil) -> Locale {
        Locale(identifier: normalizedIdentifier(from: identifier))
    }

    nonisolated static func lprojResourceName(for identifier: String?) -> String {
        language(from: identifier)?.lprojResourceName ?? fallback.lprojResourceName
    }

    nonisolated private static func language(from identifier: String?) -> AppLanguage? {
        let normalized = (identifier ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")

        guard !normalized.isEmpty else {
            return nil
        }

        let lowercaseIdentifier = normalized.lowercased()
        let segments = lowercaseIdentifier.split(separator: "-")

        switch lowercaseIdentifier {
        case "zh-cn", "zh-hans", "zh-hans-cn", "zh":
            return .simplifiedChinese
        case "zh-hk", "zh-hant-hk":
            return .traditionalChineseHongKong
        case "zh-tw", "zh-hant", "zh-hant-tw":
            return .traditionalChineseTaiwan
        default:
            break
        }

        if segments.first == "zh" {
            if segments.contains("hk") {
                return .traditionalChineseHongKong
            }

            if segments.contains("tw") || segments.contains("hant") {
                return .traditionalChineseTaiwan
            }

            return .simplifiedChinese
        }

        if lowercaseIdentifier.hasPrefix("en") {
            return .english
        }

        if lowercaseIdentifier.hasPrefix("ja") {
            return .japanese
        }

        if lowercaseIdentifier.hasPrefix("ko") {
            return .korean
        }

        return nil
    }
}
