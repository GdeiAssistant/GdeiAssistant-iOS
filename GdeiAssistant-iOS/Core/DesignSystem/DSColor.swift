import SwiftUI
import UIKit

extension UIColor {
    convenience init(dsLight: UInt, dark dsDark: UInt) {
        self.init { trait in
            let value = trait.userInterfaceStyle == .dark ? dsDark : dsLight
            return UIColor(
                red: CGFloat((value >> 16) & 0xFF) / 255.0,
                green: CGFloat((value >> 8) & 0xFF) / 255.0,
                blue: CGFloat(value & 0xFF) / 255.0,
                alpha: 1.0
            )
        }
    }
}

extension Color {
    init(dsLight: UInt, dark dsDark: UInt) {
        self.init(UIColor(dsLight: dsLight, dark: dsDark))
    }
}

/// Shared GdeiAssistant brand tokens (Web / Mini Program / Android / iOS).
enum DSColor {
    static let primary = Color(dsLight: 0x0E8F6E, dark: 0x34C79A)
    static let primarySoft = Color(dsLight: 0xE3F3EE, dark: 0x12332A)
    static let onPrimary = Color(dsLight: 0xFFFFFF, dark: 0x0E1513)

    static let background = Color(dsLight: 0xF4F7F6, dark: 0x0E1513)
    static let surface = Color(dsLight: 0xFFFFFF, dark: 0x151E1B)
    static let surfaceRaised = Color(dsLight: 0xFFFFFF, dark: 0x1C2724)
    static let fieldBackground = Color(dsLight: 0xF4F7F6, dark: 0x1C2724)

    static let title = Color(dsLight: 0x11201C, dark: 0xE6EEEB)
    static let subtitle = Color(dsLight: 0x4E5F5A, dark: 0xA3B3AE)
    static let tertiaryText = Color(dsLight: 0x6F7F7A, dark: 0x84948F)

    static let border = Color(dsLight: 0xDDE6E3, dark: 0x2A3733)
    static let divider = Color(dsLight: 0xE9EFED, dark: 0x222D2A)

    static let danger = Color(dsLight: 0xD14343, dark: 0xF07171)
    static let warning = Color(dsLight: 0xB7791F, dark: 0xE0A54A)
}
