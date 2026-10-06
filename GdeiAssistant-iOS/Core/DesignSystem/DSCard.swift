import SwiftUI

struct DSCard<Content: View>: View {
    var padding: CGFloat
    private let content: Content

    init(padding: CGFloat = DSSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface, in: DSRadius.cardShape)
    }
}

struct DSSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
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
    let text: String
    var tint: Color = DSColor.primary
    var background: Color = DSColor.primarySoft

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }
}

struct DSIconTile: View {
    let systemName: String
    var size: CGFloat = 28
    var tint: Color = DSColor.primary
    var background: Color = DSColor.primarySoft

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Inset-grouped section for scroll-based pages: caption header outside, one
/// continuous surface inside. Mirrors the native `.insetGrouped` list look.
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

/// Hairline separator for rows inside `DSGroupedSection`.
struct DSRowDivider: View {
    var leadingInset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(DSColor.divider)
            .frame(height: 0.5)
            .padding(.leading, leadingInset)
    }
}

/// Title / value row with native 44pt minimum height.
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
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
