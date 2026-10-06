import SwiftUI

struct DeleteAccountView: View {
    @StateObject private var viewModel: DeleteAccountViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var showConfirmation = false

    init(viewModel: DeleteAccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                riskRow(localizedString("deleteAccount.risk1"))
                riskRow(localizedString("deleteAccount.risk2"))
                riskRow(localizedString("deleteAccount.risk3"))
                riskRow(localizedString("deleteAccount.risk4"))
                riskRow(localizedString("deleteAccount.risk5"))
            } header: {
                Label(localizedString("deleteAccount.warning"), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(DSColor.danger)
            }

            Section {
                SecureFormField(title: localizedString("deleteAccount.password"), placeholder: localizedString("deleteAccount.passwordPlaceholder"), text: $viewModel.password)

                Toggle(localizedString("deleteAccount.agree"), isOn: $viewModel.agreed)
                    .tint(DSColor.primary)
            } footer: {
                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                DSButton(
                    title: localizedString("deleteAccount.confirmBtn"),
                    icon: "person.crop.circle.badge.xmark",
                    variant: .destructive,
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: !viewModel.canSubmit
                ) {
                    showConfirmation = true
                }
                .dsActionRow()
            }
        }
        .dsForm()
        .navigationTitle(localizedString("deleteAccount.title"))
        .confirmationDialog(localizedString("deleteAccount.confirmDialog"), isPresented: $showConfirmation, titleVisibility: .visible) {
            Button(localizedString("deleteAccount.proceed"), role: .destructive) {
                Task {
                    await viewModel.submit()
                    if case .success = viewModel.submitState {
                        await container.authManager.logout()
                    }
                }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        } message: {
            Text(localizedString("deleteAccount.verifyNote"))
        }
    }

    private func riskRow(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DSColor.title)
        } icon: {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(DSColor.danger)
        }
    }
}
