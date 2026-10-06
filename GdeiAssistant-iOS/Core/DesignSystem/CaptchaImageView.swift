import SwiftUI
import UIKit

struct CaptchaImageView: View {
    let base64String: String?
    let isLoading: Bool
    let refreshAction: () -> Void

    var body: some View {
        Button(action: refreshAction) {
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                    .fill(DSColor.fieldBackground)

                if isLoading {
                    ProgressView()
                        .tint(DSColor.primary)
                } else if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Label(localizedString("captcha.tapToRefresh"), systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                        .labelStyle(.iconOnly)
                }
            }
            .frame(width: 110, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localizedString("captcha.refreshAccessibility"))
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
