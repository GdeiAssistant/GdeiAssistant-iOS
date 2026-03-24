import SwiftUI

enum DSTypography {
    static let largeTitle: Font = .system(size: 28, weight: .bold)
    static let title: Font = .system(size: 20, weight: .semibold)
    static let headline: Font = .system(size: 16, weight: .semibold)
    static let body: Font = .system(size: 15, weight: .regular)
    static let callout: Font = .system(size: 14, weight: .regular)
    static let caption: Font = .system(size: 12, weight: .medium)
    static let mono: Font = .system(size: 15, weight: .medium, design: .monospaced)
    static let monoLarge: Font = .system(size: 22, weight: .bold, design: .monospaced)
}
