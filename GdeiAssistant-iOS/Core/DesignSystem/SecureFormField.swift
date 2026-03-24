import SwiftUI
import UIKit

struct SecureFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType? = .password
    var keyboardType: UIKeyboardType = .default

    @State private var isSecureEntry = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.subtitle)

            HStack(spacing: 8) {
                Group {
                    if isSecureEntry {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                            .keyboardType(keyboardType)
                    } else {
                        TextField(placeholder, text: $text)
                            .textContentType(textContentType)
                            .keyboardType(keyboardType)
                    }
                }
                .font(.body)
                .foregroundStyle(DSColor.title)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)

                Button {
                    isSecureEntry.toggle()
                } label: {
                    Image(systemName: isSecureEntry ? "eye.slash" : "eye")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
