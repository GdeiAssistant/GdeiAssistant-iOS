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
