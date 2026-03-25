import SwiftUI

struct BindEmailView: View {
    @StateObject private var viewModel: BindEmailViewModel
    @State private var showUnbindConfirmation = false

    init(viewModel: BindEmailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    infoRow(localizedString("bindEmail.status"), viewModel.status.isBound ? localizedString("bindPhone.bound") : localizedString("bindPhone.unbound"))
                    infoRow(localizedString("bindEmail.currentEmail"), viewModel.status.maskedValue)
                }

                DSCard {
                    DSInputField(title: localizedString("bindEmail.email"), placeholder: localizedString("bindEmail.emailPlaceholder"), text: $viewModel.email, keyboardType: .emailAddress)
                    DSInputField(title: localizedString("bindEmail.code"), placeholder: localizedString("bindEmail.codePlaceholder"), text: $viewModel.randomCode, keyboardType: .numberPad)

                    DSButton(
                        title: retryCodeButtonTitle,
                        icon: "envelope.badge",
                        variant: .secondary,
                        isLoading: viewModel.isSendingCode,
                        isDisabled: !viewModel.canSendCode
                    ) {
                        Task { await viewModel.sendCode() }
                    }

                    if case .failure(let message) = viewModel.submitState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: localizedString("bindEmail.bind"),
                    icon: "envelope.badge.person.crop",
                    isLoading: viewModel.submitState.isSubmitting
                ) {
                    Task { await viewModel.bind() }
                }

                if viewModel.status.isBound {
                    DSButton(title: localizedString("bindEmail.unbind"), icon: "envelope.open.fill", variant: .destructive) {
                        showUnbindConfirmation = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle(localizedString("bindEmail.title"))
        .task {
            await viewModel.load()
        }
        .confirmationDialog(localizedString("bindEmail.confirmUnbind"), isPresented: $showUnbindConfirmation, titleVisibility: .visible) {
            Button(localizedString("bindPhone.confirmUnbindBtn"), role: .destructive) {
                Task { await viewModel.unbind() }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button(localizedString("common.understood")) { viewModel.submitState = .idle }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .foregroundStyle(DSColor.title)
        }
    }

    private var retryCodeButtonTitle: String {
        guard viewModel.countdown > 0 else {
            return localizedString("bindPhone.getCode")
        }

        return String(
            format: localizedString("common.retryAfterSeconds"),
            locale: Locale(identifier: UserPreferences.currentLocale),
            viewModel.countdown
        )
    }
}
