import SwiftUI

/// Sticky-note paper tones for the Secret module, tuned to Lingnan botanical
/// and mineral ink pigments. Light values stay subtle and warm; dark values drop
/// luminance while preserving crisp >= 4.5:1 ink contrast and 1pt hairline framing.
enum DSSecretPalette {
    struct Palette {
        let background: Color
        let textColor: Color
        let borderColor: Color
    }

    static func palette(for themeID: Int) -> Palette {
        switch themeID {
        case 1:
            // Warm bamboo parchment
            return Palette(
                background: Color(dsLight: 0xF5F1E3, dark: 0x262216),
                textColor: ink(for: 1),
                borderColor: Color(dsLight: 0xE2DAC2, dark: 0x3C3522)
            )
        case 2:
            // Camellia clay paper
            return Palette(
                background: Color(dsLight: 0xF4E4E2, dark: 0x2B1A1B),
                textColor: ink(for: 2),
                borderColor: Color(dsLight: 0xE1C4C0, dark: 0x472A2B)
            )
        case 3:
            // Celadon mist
            return Palette(
                background: Color(dsLight: 0xE6EFEA, dark: 0x172521),
                textColor: ink(for: 3),
                borderColor: Color(dsLight: 0xCADBD3, dark: 0x283F38)
            )
        case 4:
            // Kapok ochre wash
            return Palette(
                background: Color(dsLight: 0xF7E8DC, dark: 0x2D1E15),
                textColor: ink(for: 4),
                borderColor: Color(dsLight: 0xE6CBB7, dark: 0x483021)
            )
        case 5:
            // Moss sage leaf
            return Palette(
                background: Color(dsLight: 0xE7EFE5, dark: 0x1B261C),
                textColor: ink(for: 5),
                borderColor: Color(dsLight: 0xCDDCC9, dark: 0x2D3E2E)
            )
        case 6:
            // Bauhinia dusk paper
            return Palette(
                background: Color(dsLight: 0xEEEAF6, dark: 0x211B2E),
                textColor: ink(for: 6),
                borderColor: Color(dsLight: 0xD9D0EA, dark: 0x352B49)
            )
        case 7:
            // Pearl River indigo mist
            return Palette(
                background: Color(dsLight: 0xE6EDF5, dark: 0x18212D),
                textColor: ink(for: 7),
                borderColor: Color(dsLight: 0xCBD7E6, dark: 0x29374A)
            )
        case 8:
            // Terracotta seal ink
            return Palette(
                background: Color(dsLight: 0xF3E2DD, dark: 0x2D1B18),
                textColor: ink(for: 8),
                borderColor: Color(dsLight: 0xDFC2BA, dark: 0x482B26)
            )
        case 9:
            // Osmathus amber parchment
            return Palette(
                background: Color(dsLight: 0xF6ECD7, dark: 0x292114),
                textColor: ink(for: 9),
                borderColor: Color(dsLight: 0xE4D1AD, dark: 0x423520)
            )
        case 10:
            // Deep stone blue ink
            return Palette(
                background: Color(dsLight: 0x384B6E, dark: 0x161E2C),
                textColor: ink(for: 10),
                borderColor: Color(dsLight: 0x2D3C58, dark: 0x26344B)
            )
        case 11:
            // Old pine ink teal
            return Palette(
                background: Color(dsLight: 0x2B5952, dark: 0x132623),
                textColor: ink(for: 11),
                borderColor: Color(dsLight: 0x224741, dark: 0x21403B)
            )
        case 12:
            // Sandalwood bark ink
            return Palette(
                background: Color(dsLight: 0x624835, dark: 0x241B14),
                textColor: ink(for: 12),
                borderColor: Color(dsLight: 0x4F3A2A, dark: 0x3B2C21)
            )
        default:
            return Palette(
                background: DSColor.surface,
                textColor: DSColor.title,
                borderColor: DSColor.border
            )
        }
    }

    private static func ink(for themeID: Int) -> Color {
        switch themeID {
        case 10, 11, 12:
            // Deep mineral ink backgrounds pair with warm rice-paper text in both appearances.
            return Color(dsLight: 0xF7F6F2, dark: 0xF1EFEA)
        default:
            return Color(dsLight: 0x14231F, dark: 0xF1EFEA)
        }
    }
}
