import SwiftUI

struct DeleteAccountView: View {
    @StateObject private var viewModel: DeleteAccountViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var showConfirmation = false

    init(viewModel: DeleteAccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    Label(localizedString("deleteAccount.warning"), systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(DSColor.danger)

                    riskRow(localizedString("deleteAccount.risk1"))
                    riskRow(localizedString("deleteAccount.risk2"))
                    riskRow(localizedString("deleteAccount.risk3"))
                    riskRow(localizedString("deleteAccount.risk4"))
                    riskRow(localizedString("deleteAccount.risk5"))
                }

                DSCard {
                    SecureFormField(title: localizedString("deleteAccount.password"), placeholder: localizedString("deleteAccount.passwordPlaceholder"), text: $viewModel.password)

                    Toggle(localizedString("deleteAccount.agree"), isOn: $viewModel.agreed)

                    if case .failure(let message) = viewModel.submitState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: localizedString("deleteAccount.confirmBtn"),
                    icon: "person.crop.circle.badge.xmark",
                    variant: .destructive,
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: !viewModel.canSubmit
                ) {
                    showConfirmation = true
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
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
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(DSColor.danger)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
    }
}
