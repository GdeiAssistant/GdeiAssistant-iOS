import SwiftUI

struct DSLoadingView: View {
    var text: String = "加载中..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(DSColor.primary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
