import SwiftUI

struct DSLoadingView: View {
    var text: String = localizedString("common.loading")

    var body: some View {
        ContentUnavailableView {
            ProgressView()
                .controlSize(.large)
                .tint(DSColor.primary)
        } description: {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
