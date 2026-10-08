import SwiftUI

enum DSSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum DSRadius {
    static let card: CGFloat = 14
    static let control: CGFloat = 10
    static let compact: CGFloat = 6

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: card, style: .continuous)
    }

    static var controlShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: control, style: .continuous)
    }
}

enum DSMotion {
    static let press: Animation = .easeOut(duration: 0.12)
}

extension View {
    func dsScreenBackground() -> some View {
        background(DSColor.background.ignoresSafeArea())
    }

    func dsListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(DSColor.background.ignoresSafeArea())
    }

    func dsSurface(_ color: Color = DSColor.surface, radius: CGFloat = DSRadius.card) -> some View {
        background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func dsFieldBackground() -> some View {
        background(DSColor.fieldBackground, in: DSRadius.controlShape)
    }
}

extension View {
    /// Full-width action button row inside a Form/List section (no row chrome).
    func dsActionRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }

    /// Native grouped Form chrome on the brand background.
    func dsForm() -> some View {
        formStyle(.grouped)
            .dsListBackground()
            .scrollDismissesKeyboard(.interactively)
    }
}
