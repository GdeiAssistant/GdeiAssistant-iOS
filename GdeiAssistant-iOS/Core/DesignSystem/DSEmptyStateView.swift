import SwiftUI

struct DSEmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DSColor.title, DSColor.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
