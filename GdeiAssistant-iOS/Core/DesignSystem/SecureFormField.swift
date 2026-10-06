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
        HStack(spacing: DSSpacing.xs) {
            Group {
                if isSecureEntry {
                    SecureField(title, text: $text, prompt: Text(placeholder))
                        .textContentType(textContentType)
                        .keyboardType(keyboardType)
                } else {
                    TextField(title, text: $text, prompt: Text(placeholder))
                        .textContentType(textContentType)
                        .keyboardType(keyboardType)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isSecureEntry.toggle()
            } label: {
                Image(systemName: isSecureEntry ? "eye.slash" : "eye")
                    .foregroundStyle(DSColor.subtitle)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedString(isSecureEntry ? "common.showPassword" : "common.hidePassword"))
        }
    }
}
