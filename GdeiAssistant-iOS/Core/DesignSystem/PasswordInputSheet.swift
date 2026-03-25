import SwiftUI
import UIKit

struct PasswordInputSheet: View {
    let title: String
    let message: String
    let placeholder: String
    let confirmTitle: String
    let keyboardType: UIKeyboardType
    let isSubmitting: Bool
    let errorMessage: String?
    @Binding var password: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DSCard {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(4)

                    SecureFormField(
                        title: localizedString("passwordSheet.verificationTitle"),
                        placeholder: placeholder,
                        text: $password,
                        textContentType: .password,
                        keyboardType: keyboardType
                    )

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: confirmTitle,
                    icon: "checkmark",
                    isLoading: isSubmitting,
                    isDisabled: FormValidationSupport.trimmed(password).isEmpty,
                    action: onConfirm
                )

                Spacer()
            }
            .padding(16)
            .background(DSColor.background.ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedString("common.cancel"), action: onCancel)
                }
            }
        }
    }
}
