import SwiftUI
import UIKit

extension Color {
    init(dsLight: UInt, dark dsDark: UInt) {
        self.init(
            UIColor { trait in
                let value = trait.userInterfaceStyle == .dark ? dsDark : dsLight
                return UIColor(
                    red: CGFloat((value >> 16) & 0xFF) / 255.0,
                    green: CGFloat((value >> 8) & 0xFF) / 255.0,
                    blue: CGFloat(value & 0xFF) / 255.0,
                    alpha: 1.0
                )
            }
        )
    }
}

enum DSColor {
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    static let primary = Color(dsLight: 0x047857, dark: 0x34D399)
    static let onPrimary = Color(dsLight: 0xFFFFFF, dark: 0x0F1117)

    static let secondary = Color(dsLight: 0x0FA67A, dark: 0x39C79D)
    static let warning = Color(dsLight: 0xF2A93B, dark: 0xFFC56B)
    static let danger = Color(dsLight: 0xD94A4A, dark: 0xFF7C7C)

    static let title = Color(.label)
    static let subtitle = Color(.secondaryLabel)
    static let divider = Color(.separator)
}
