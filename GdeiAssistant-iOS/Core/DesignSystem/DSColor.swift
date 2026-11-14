import SwiftUI
import UIKit

extension UIColor {
    convenience init(dsHex value: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    convenience init(dsLight: UInt, dark dsDark: UInt) {
        self.init { trait in
            let value = trait.userInterfaceStyle == .dark ? dsDark : dsLight
            return UIColor(dsHex: value)
        }
    }
}

extension Color {
    init(dsLight: UInt, dark dsDark: UInt) {
        self.init(UIColor(dsLight: dsLight, dark: dsDark))
    }
}

/// Curated Lingnan campus accent palettes persisted via `gdei.theme.accent`.
enum DSCampusAccent: String, CaseIterable, Identifiable, Sendable {
    case banyan
    case kapok
    case haizhu
    case bauhinia

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .banyan:
            return "appearance.accent.banyan"
        case .kapok:
            return "appearance.accent.kapok"
        case .haizhu:
            return "appearance.accent.haizhu"
        case .bauhinia:
            return "appearance.accent.bauhinia"
        }
    }

    var subtitleKey: String {
        switch self {
        case .banyan:
            return "appearance.accent.banyanSubtitle"
        case .kapok:
            return "appearance.accent.kapokSubtitle"
        case .haizhu:
            return "appearance.accent.haizhuSubtitle"
        case .bauhinia:
            return "appearance.accent.bauhiniaSubtitle"
        }
    }

    static var current: DSCampusAccent {
        guard let raw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedAccent),
              let accent = DSCampusAccent(rawValue: raw) else {
            return .banyan
        }
        return accent
    }

    var lightPrimaryHex: UInt {
        switch self {
        case .banyan: return 0x0E7C61
        case .kapok: return 0xC85A32
        case .haizhu: return 0x1D4ED8
        case .bauhinia: return 0x6D28D9
        }
    }

    var darkPrimaryHex: UInt {
        switch self {
        case .banyan: return 0x2DD4BF
        case .kapok: return 0xFB923C
        case .haizhu: return 0x60A5FA
        case .bauhinia: return 0xA78BFA
        }
    }

    var lightPrimarySoftHex: UInt {
        switch self {
        case .banyan: return 0xE4F3EE
        case .kapok: return 0xFBECE6
        case .haizhu: return 0xE8EFFD
        case .bauhinia: return 0xF1EAFF
        }
    }

    var darkPrimarySoftHex: UInt {
        switch self {
        case .banyan: return 0x12332A
        case .kapok: return 0x361F14
        case .haizhu: return 0x142642
        case .bauhinia: return 0x24183D
        }
    }

    func uiPrimary(isDark: Bool) -> UIColor {
        if self == .banyan {
            return isDark
                ? UIColor(GeneratedDesignTokens.Dark.primary)
                : UIColor(GeneratedDesignTokens.Light.primary)
        }
        return UIColor(dsHex: isDark ? darkPrimaryHex : lightPrimaryHex)
    }

    func uiPrimarySoft(isDark: Bool) -> UIColor {
        if self == .banyan {
            return isDark
                ? UIColor(GeneratedDesignTokens.Dark.primarySoft)
                : UIColor(GeneratedDesignTokens.Light.primarySoft)
        }
        return UIColor(dsHex: isDark ? darkPrimarySoftHex : lightPrimarySoftHex)
    }

    func uiOnPrimary(isDark: Bool) -> UIColor {
        isDark
            ? UIColor(GeneratedDesignTokens.Dark.bg)
            : UIColor(GeneratedDesignTokens.Light.surface)
    }

    var primary: Color {
        Color(UIColor { trait in
            uiPrimary(isDark: trait.userInterfaceStyle == .dark)
        })
    }

    var primarySoft: Color {
        Color(UIColor { trait in
            uiPrimarySoft(isDark: trait.userInterfaceStyle == .dark)
        })
    }

    var onPrimary: Color {
        Color(UIColor { trait in
            uiOnPrimary(isDark: trait.userInterfaceStyle == .dark)
        })
    }
}

private struct DSCampusAccentEnvironmentKey: EnvironmentKey {
    static let defaultValue: DSCampusAccent = .banyan
}

extension EnvironmentValues {
    var dsCampusAccent: DSCampusAccent {
        get { self[DSCampusAccentEnvironmentKey.self] }
        set { self[DSCampusAccentEnvironmentKey.self] = newValue }
    }
}

/// Shared GdeiAssistant Lingnan Editorial brand tokens (Light: Warm Paper, Dark: Nocturnal Ink).
enum DSColor {
    static var primary: Color {
        Color(UIColor { trait in
            DSCampusAccent.current.uiPrimary(isDark: trait.userInterfaceStyle == .dark)
        })
    }

    static var primarySoft: Color {
        Color(UIColor { trait in
            DSCampusAccent.current.uiPrimarySoft(isDark: trait.userInterfaceStyle == .dark)
        })
    }

    static var onPrimary: Color {
        Color(UIColor { trait in
            DSCampusAccent.current.uiOnPrimary(isDark: trait.userInterfaceStyle == .dark)
        })
    }

    static let background = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.bg)
            : UIColor(GeneratedDesignTokens.Light.bg)
    })

    static let surface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.surface)
            : UIColor(GeneratedDesignTokens.Light.surface)
    })

    static let surfaceSubtle = Color(dsLight: 0xF0EEE8, dark: 0x1C2724)
    static let surfaceRaised = Color(dsLight: 0xFFFFFF, dark: 0x1C2724)
    static let fieldBackground = Color(dsLight: 0xF0EEE8, dark: 0x1C2724)

    static let title = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.text1)
            : UIColor(GeneratedDesignTokens.Light.text1)
    })

    static let subtitle = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.text2)
            : UIColor(GeneratedDesignTokens.Light.text2)
    })

    static let tertiaryText = Color(dsLight: 0x7A8580, dark: 0x6F7E78)

    static let border = Color(dsLight: 0xE5E2DC, dark: 0x22302B)
    static let divider = Color(dsLight: 0xECE9E2, dark: 0x1D2925)

    static let danger = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.danger)
            : UIColor(GeneratedDesignTokens.Light.danger)
    })

    static let warning = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(GeneratedDesignTokens.Dark.warning)
            : UIColor(GeneratedDesignTokens.Light.warning)
    })
}
