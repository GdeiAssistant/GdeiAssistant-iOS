import SwiftUI

/// Sticky-note theme colors for the secret module.
///
/// Each theme carries a light and a dark value. Dark values keep the hue but
/// drop luminance so the note still reads as colored paper in dark mode, and
/// every combination meets WCAG AA (>= 4.5:1) against its paired text color:
/// ink `#11201C` on the light values, light ink `#EAF3F0` on the dark values.
enum DSSecretPalette {
    struct Palette {
        let background: Color
        let textColor: Color
    }

    static func palette(for themeID: Int) -> Palette {
        switch themeID {
        case 1:
            return Palette(background: Color(dsLight: 0xF5F0DE, dark: 0x625420), textColor: ink(for: 1))
        case 2:
            return Palette(background: Color(dsLight: 0xD6858F, dark: 0x48191F), textColor: ink(for: 2))
        case 3:
            return Palette(background: Color(dsLight: 0x8FADC9, dark: 0x203140), textColor: ink(for: 3))
        case 4:
            return Palette(background: Color(dsLight: 0xE8AB7D, dark: 0x532D11), textColor: ink(for: 4))
        case 5:
            return Palette(background: Color(dsLight: 0x8ABDA1, dark: 0x223A2C), textColor: ink(for: 5))
        case 6:
            return Palette(background: Color(dsLight: 0xA38AC4, dark: 0x2D203E), textColor: ink(for: 6))
        case 7:
            return Palette(background: Color(dsLight: 0x5EA1BA, dark: 0x182E36), textColor: ink(for: 7))
        case 8:
            return Palette(background: Color(dsLight: 0xED8570, dark: 0x55190D), textColor: ink(for: 8))
        case 9:
            return Palette(background: Color(dsLight: 0xF2BA63, dark: 0x563809), textColor: ink(for: 9))
        case 10:
            return Palette(background: Color(dsLight: 0x546B9E, dark: 0x181E2C), textColor: ink(for: 10))
        case 11:
            return Palette(background: Color(dsLight: 0x427A73, dark: 0x182B28), textColor: ink(for: 11))
        case 12:
            return Palette(background: Color(dsLight: 0x856147, dark: 0x2B2018), textColor: ink(for: 12))
        default:
            return Palette(background: DSColor.surface, textColor: DSColor.title)
        }
    }

    private static func ink(for themeID: Int) -> Color {
        switch themeID {
        case 10, 11, 12:
            // Light values are deep enough that white reads better than ink.
            return Color(dsLight: 0xFFFFFF, dark: 0xEAF3F0)
        default:
            return Color(dsLight: 0x11201C, dark: 0xEAF3F0)
        }
    }
}
