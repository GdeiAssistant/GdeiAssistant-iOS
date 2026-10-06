import SwiftUI

struct DSErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(localizedString("common.error"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retryAction {
                Button(localizedString("common.retry"), systemImage: "arrow.clockwise", action: retryAction)
                    .buttonStyle(.bordered)
                    .tint(DSColor.primary)
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DSColor.title, DSColor.danger)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
