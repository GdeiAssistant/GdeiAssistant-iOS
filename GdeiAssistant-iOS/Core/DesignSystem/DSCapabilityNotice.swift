import SwiftUI

struct DSCapabilityNotice: View {
    let title: String
    let message: String
    var icon: String = "exclamationmark.triangle"

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(DSColor.warning)
                .accessibilityHidden(true)
        }
        .padding(.vertical, DSSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}
