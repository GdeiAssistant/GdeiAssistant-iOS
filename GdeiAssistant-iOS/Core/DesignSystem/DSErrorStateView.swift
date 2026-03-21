import SwiftUI

struct DSErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(DSColor.danger)
                .accessibilityHidden(true)

            Text("加载失败")
                .font(.headline)
                .foregroundStyle(DSColor.title)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .multilineTextAlignment(.center)

            if let retryAction {
                DSButton(title: "重试", icon: "arrow.clockwise", variant: .secondary, action: retryAction)
                    .frame(maxWidth: 180)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
