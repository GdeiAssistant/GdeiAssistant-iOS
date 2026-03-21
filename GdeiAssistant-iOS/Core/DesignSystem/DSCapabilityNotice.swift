import SwiftUI

struct DSCapabilityNotice: View {
    let title: String
    let message: String
    var icon: String = "exclamationmark.bubble"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(DSColor.warning)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DSColor.divider.opacity(0.12), lineWidth: 1)
        )
    }
}
