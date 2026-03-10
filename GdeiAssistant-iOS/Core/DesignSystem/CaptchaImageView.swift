import SwiftUI
import UIKit

struct CaptchaImageView: View {
    let base64String: String?
    let isLoading: Bool
    let refreshAction: () -> Void

    var body: some View {
        Button(action: refreshAction) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))

                if isLoading {
                    ProgressView()
                        .tint(DSColor.primary)
                } else if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        Text("点击刷新")
                            .font(.caption)
                    }
                    .foregroundStyle(DSColor.subtitle)
                }
            }
            .frame(width: 110, height: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("刷新验证码")
    }

    private var imageData: Data? {
        guard let base64String else { return nil }

        let normalized: String
        if let dataRange = base64String.range(of: ",") {
            normalized = String(base64String[dataRange.upperBound...])
        } else {
            normalized = base64String
        }

        return Data(base64Encoded: normalized)
    }
}
