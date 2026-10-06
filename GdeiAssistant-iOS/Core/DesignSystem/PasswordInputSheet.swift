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
            Form {
                Section {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .listRowBackground(DSColor.surface)
                }

                Section {
                    SecureFormField(
                        title: localizedString("passwordSheet.verificationTitle"),
                        placeholder: placeholder,
                        text: $password,
                        textContentType: .password,
                        keyboardType: keyboardType
                    )
                    .listRowBackground(DSColor.surface)

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                            .listRowBackground(DSColor.surface)
                    }
                }

                Section {
                    DSButton(
                        title: confirmTitle,
                        icon: "checkmark",
                        isLoading: isSubmitting,
                        isDisabled: FormValidationSupport.trimmed(password).isEmpty,
                        action: onConfirm
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }
            .dsListBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizedString("common.cancel"), action: onCancel)
                }
            }
        }
    }
}
