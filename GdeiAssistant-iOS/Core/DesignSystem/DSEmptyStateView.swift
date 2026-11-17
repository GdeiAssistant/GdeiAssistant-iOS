import SwiftUI

struct DSEmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(DSColor.primary)
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DSColor.title, DSColor.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
