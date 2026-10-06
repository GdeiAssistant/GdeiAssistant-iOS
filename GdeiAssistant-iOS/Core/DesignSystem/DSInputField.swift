import SwiftUI
import UIKit

struct DSInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    private let accessibilityIdentifier: String?

    private let secureToggle: Binding<Bool>?
    private let textContentType: UITextContentType?
    private let keyboardType: UIKeyboardType

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        accessibilityIdentifier: String? = nil,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.accessibilityIdentifier = accessibilityIdentifier
        self.secureToggle = nil
        self.textContentType = textContentType
        self.keyboardType = keyboardType
    }

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecureEntry: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        textContentType: UITextContentType? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.accessibilityIdentifier = accessibilityIdentifier
        self.secureToggle = isSecureEntry
        self.textContentType = textContentType
        self.keyboardType = .default
    }

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            inputView
            if let secureToggle {
                Button {
                    secureToggle.wrappedValue.toggle()
                } label: {
                    Image(systemName: secureToggle.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(DSColor.subtitle)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    localizedString(
                        secureToggle.wrappedValue ? "common.showPassword" : "common.hidePassword"
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var inputView: some View {
        if let secureToggle, secureToggle.wrappedValue {
            SecureField(title, text: $text, prompt: Text(placeholder))
                .textContentType(textContentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .applyAccessibilityIdentifier(accessibilityIdentifier)
        } else {
            TextField(title, text: $text, prompt: Text(placeholder))
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .applyAccessibilityIdentifier(accessibilityIdentifier)
        }
    }
}

private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
