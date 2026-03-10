import SwiftUI

struct DSEmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(DSColor.subtitle)

            Text(title)
                .font(.headline)
                .foregroundStyle(DSColor.title)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
