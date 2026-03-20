import SwiftUI

enum DSTheme: String, CaseIterable, Identifiable {
    case campusGreen = "campus-green"
    case classicBlue = "classic-blue"
    case vividPurple = "vivid-purple"
    case warmOrange = "warm-orange"
    case freshTeal = "fresh-teal"
    case rosePink = "rose-pink"
    case deepIndigo = "deep-indigo"
    case amberGold = "amber-gold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .campusGreen: return "校园绿"
        case .classicBlue: return "天空蓝"
        case .vividPurple: return "薰衣草"
        case .warmOrange: return "活力橙"
        case .freshTeal: return "清新青"
        case .rosePink: return "元气粉"
        case .deepIndigo: return "深空靛"
        case .amberGold: return "琥珀金"
        }
    }

    var lightPrimary: UInt {
        switch self {
        case .campusGreen: return 0x047857
        case .classicBlue: return 0x2563EB
        case .vividPurple: return 0x7C3AED
        case .warmOrange: return 0xC2410C
        case .freshTeal: return 0x0F766E
        case .rosePink: return 0xE11D48
        case .deepIndigo: return 0x4F46E5
        case .amberGold: return 0xB45309
        }
    }

    var darkPrimary: UInt {
        switch self {
        case .campusGreen: return 0x34D399
        case .classicBlue: return 0x3B82F6
        case .vividPurple: return 0xA78BFA
        case .warmOrange: return 0xFB923C
        case .freshTeal: return 0x2DD4BF
        case .rosePink: return 0xFB7185
        case .deepIndigo: return 0x818CF8
        case .amberGold: return 0xFBBF24
        }
    }

    var primaryColor: Color {
        Color(dsLight: lightPrimary, dark: darkPrimary)
    }

    var onPrimaryColor: Color {
        Color(dsLight: 0xFFFFFF, dark: 0x0F1117)
    }
}
