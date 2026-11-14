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
    static let card: CGFloat = GeneratedDesignTokens.cardRadius
    static let control: CGFloat = 10
    static let compact: CGFloat = 6

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: card, style: .continuous)
    }

    static var controlShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: control, style: .continuous)
    }
}

enum DSTypography {
    static let displaySerif: Font = .system(.largeTitle, design: .serif).weight(.semibold)
    static let title2Serif: Font = .system(.title2, design: .serif).weight(.semibold)
    static let title3Serif: Font = .system(.title3, design: .serif).weight(.semibold)
    static let headlineSerif: Font = .system(.headline, design: .serif).weight(.semibold)
    static let pullQuoteSerif: Font = .system(.body, design: .serif)

    static let captionMono: Font = .caption.monospacedDigit()
    static let footnoteMono: Font = .footnote.monospacedDigit()
    static let subheadlineMono: Font = .subheadline.monospacedDigit()
    static let headlineMono: Font = .headline.monospacedDigit()
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

    func dsSurface(
        _ color: Color = DSColor.surface,
        radius: CGFloat = DSRadius.card,
        borderColor: Color = DSColor.border
    ) -> some View {
        background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    func dsFieldBackground() -> some View {
        background(DSColor.fieldBackground, in: DSRadius.controlShape)
            .overlay(
                DSRadius.controlShape
                    .stroke(DSColor.border, lineWidth: 1)
            )
    }

    func dsEditorialDisplay() -> some View {
        font(DSTypography.displaySerif)
    }

    func dsEditorialTitle() -> some View {
        font(DSTypography.title2Serif)
    }

    func dsEditorialHeadline() -> some View {
        font(DSTypography.headlineSerif)
    }

    func dsTabularDigits() -> some View {
        monospacedDigit()
    }

    func dsHairlineBorder(
        _ cornerRadius: CGFloat = DSRadius.card,
        color: Color = DSColor.border,
        lineWidth: CGFloat = 1
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(color, lineWidth: lineWidth)
        )
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
