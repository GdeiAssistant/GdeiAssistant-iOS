import SwiftUI
import UIKit

struct DSInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    private let secureToggle: Binding<Bool>?
    private let textContentType: UITextContentType?
    private let keyboardType: UIKeyboardType

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.secureToggle = nil
        self.textContentType = textContentType
        self.keyboardType = keyboardType
    }

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecureEntry: Binding<Bool>,
        textContentType: UITextContentType? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.secureToggle = isSecureEntry
        self.textContentType = textContentType
        self.keyboardType = .default
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.subtitle)

            HStack(spacing: 8) {
                inputView

                if let secureToggle {
                    Button {
                        secureToggle.wrappedValue.toggle()
                    } label: {
                        Image(systemName: secureToggle.wrappedValue ? "eye.slash" : "eye")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(secureToggle.wrappedValue ? "显示密码" : "隐藏密码")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var inputView: some View {
        if let secureToggle, secureToggle.wrappedValue {
            SecureField(placeholder, text: $text)
                .textContentType(textContentType)
                .font(.body)
                .foregroundStyle(DSColor.title)
                .autocapitalization(.none)
        } else {
            TextField(placeholder, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .font(.body)
                .foregroundStyle(DSColor.title)
                .autocapitalization(.none)
        }
    }
}
