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
        Group {
            switch variant {
            case .primary:
                rawButton
                    .buttonStyle(.borderedProminent)
                    .tint(DSColor.primary)
            case .secondary:
                rawButton
                    .buttonStyle(.bordered)
                    .tint(DSColor.primary)
            case .destructive:
                rawButton
                    .buttonStyle(.borderedProminent)
                    .tint(DSColor.danger)
            }
        }
        .buttonBorderShape(.roundedRectangle(radius: DSRadius.control))
        .controlSize(.large)
        .applyAccessibilityIdentifier(accessibilityIdentifier)
        .disabled(isLoading || isDisabled)
    }

    private var rawButton: some View {
        Button(role: variant == .destructive ? .destructive : nil, action: action) {
            HStack(spacing: DSSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

/// Opacity-only press feedback; layout bounds never shift. Honors Reduce Motion.
struct DSPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? (reduceMotion ? 1 : 0.72) : 1)
            .animation(reduceMotion ? nil : DSMotion.press, value: configuration.isPressed)
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
