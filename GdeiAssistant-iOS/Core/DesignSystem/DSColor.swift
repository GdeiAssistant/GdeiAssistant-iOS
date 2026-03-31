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

    static let primary = Color.accentColor
    static let onPrimary = Color.white

    static let secondary = Color(dsLight: 0x5AC8FA, dark: 0x64D2FF)
    static let warning = Color(dsLight: 0xF2A93B, dark: 0xFFC56B)
    static let danger = Color(dsLight: 0xD94A4A, dark: 0xFF7C7C)

    static let title = Color(.label)
    static let subtitle = Color(.secondaryLabel)
    static let divider = Color(.separator)
}
