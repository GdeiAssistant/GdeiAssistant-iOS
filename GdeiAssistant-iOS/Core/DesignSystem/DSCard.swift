import SwiftUI

enum DSCardSurfaceStyle {
    case elevated
    case canvas
}

struct DSCard<Content: View>: View {
    @Environment(\.dsCampusAccent) private var campusAccent
    var padding: CGFloat
    var surfaceStyle: DSCardSurfaceStyle
    private let content: Content

    init(
        padding: CGFloat = DSSpacing.md,
        surfaceStyle: DSCardSurfaceStyle = .elevated,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.surfaceStyle = surfaceStyle
        self.content = content()
    }

    private var fillColor: Color {
        let _ = campusAccent
        switch surfaceStyle {
        case .elevated:
            return DSColor.surface
        case .canvas:
            return DSColor.background
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fillColor, in: DSRadius.cardShape)
        .overlay(
            DSRadius.cardShape
                .stroke(DSColor.border, lineWidth: 1)
        )
    }
}

struct DSSectionHeader: View {
    let title: String
    var subtitle: String?
    var useSerifTitle: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(useSerifTitle ? DSTypography.headlineSerif : .headline)
                .foregroundStyle(DSColor.title)
                .accessibilityAddTraits(.isHeader)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textCase(nil)
    }
}

struct DSTag: View {
    @Environment(\.dsCampusAccent) private var campusAccent
    let text: String
    var tint: Color? = nil
    var background: Color? = nil

    private var resolvedTint: Color {
        tint ?? campusAccent.primary
    }

    private var resolvedBackground: Color {
        background ?? campusAccent.primarySoft
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(resolvedTint)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(resolvedBackground, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(resolvedTint.opacity(0.22), lineWidth: 1)
            )
    }
}

struct DSIconTile: View {
    @Environment(\.dsCampusAccent) private var campusAccent
    let systemName: String
    var size: CGFloat = 28
    var tint: Color? = nil
    var background: Color? = nil

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint ?? campusAccent.primary)
            .frame(width: size, height: size)
            .background(
                background ?? campusAccent.primarySoft,
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// Inset-grouped section for scroll-based pages: caption header outside, one
/// continuous surface inside with a crisp 1pt hairline border.
struct DSGroupedSection<Content: View>: View {
    var title: String?
    var footer: String?
    private let content: Content

    init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DSColor.subtitle)
                    .padding(.horizontal, DSSpacing.md)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsSurface()

            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(DSColor.tertiaryText)
                    .padding(.horizontal, DSSpacing.md)
            }
        }
    }
}

/// 1pt editorial hairline rule for separating sections, lists, and feed rows.
struct DSHairlineDivider: View {
    var leadingInset: CGFloat = 0
    var trailingInset: CGFloat = 0
    var thickness: CGFloat = 1
    var color: Color = DSColor.divider

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
            .padding(.leading, leadingInset)
            .padding(.trailing, trailingInset)
    }
}

/// Hairline separator for rows inside `DSGroupedSection`.
struct DSRowDivider: View {
    var leadingInset: CGFloat = 0

    var body: some View {
        DSHairlineDivider(leadingInset: leadingInset, thickness: 1)
    }
}

/// Title / value row with native 44pt minimum height and tabular numerals.
struct DSValueRow: View {
    let title: String
    let value: String
    var valueColor: Color = DSColor.subtitle

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm) {
            Text(title)
                .font(.body)
                .foregroundStyle(DSColor.title)
            Spacer(minLength: DSSpacing.xs)
            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
