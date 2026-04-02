import SwiftUI

enum DSButtonVariant {
    case primary
    case secondary
    case destructive
}

struct DSButton: View {
    let title: String
    var icon: String?
    var variant: DSButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foregroundColor)
                        .scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                }

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .applyAccessibilityIdentifier(accessibilityIdentifier)
        .disabled(isLoading || isDisabled)
        .opacity(isLoading || isDisabled ? 0.75 : 1.0)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return DSColor.primary
        case .secondary:
            return DSColor.cardBackground
        case .destructive:
            return DSColor.danger
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return DSColor.onPrimary
        case .destructive:
            return DSColor.onPrimary
        case .secondary:
            return DSColor.title
        }
    }
}

private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
