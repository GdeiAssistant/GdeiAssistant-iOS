import Foundation

/// Returns a localized string from the bundle matching the given locale,
/// falling back to `UserPreferences.shared` locale, then `NSLocalizedString`.
///
/// Use this helper anywhere `NSLocalizedString` would ignore the SwiftUI
/// environment locale (non-SwiftUI contexts, computed properties, etc.).
nonisolated func localizedString(_ key: String, locale: String? = nil) -> String {
    let targetLocale = locale ?? UserPreferences.currentLocale
    let resolvedResource = AppLanguage.lprojResourceName(for: targetLocale)

    if let path = Bundle.main.path(forResource: resolvedResource, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    return NSLocalizedString(key, comment: "")
}
