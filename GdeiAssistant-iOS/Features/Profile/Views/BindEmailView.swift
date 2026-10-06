import SwiftUI

struct BindEmailView: View {
    @StateObject private var viewModel: BindEmailViewModel
    @State private var showUnbindConfirmation = false

    init(viewModel: BindEmailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                infoRow(localizedString("bindEmail.status"), viewModel.status.isBound ? localizedString("bindPhone.bound") : localizedString("bindPhone.unbound"))
                infoRow(localizedString("bindEmail.currentEmail"), viewModel.status.maskedValue)
            }

            Section {
                DSInputField(title: localizedString("bindEmail.email"), placeholder: localizedString("bindEmail.emailPlaceholder"), text: $viewModel.email, keyboardType: .emailAddress)
                HStack(spacing: DSSpacing.sm) {
                    DSInputField(title: localizedString("bindEmail.code"), placeholder: localizedString("bindEmail.codePlaceholder"), text: $viewModel.randomCode, keyboardType: .numberPad)
                    Button {
                        Task { await viewModel.sendCode() }
                    } label: {
                        if viewModel.isSendingCode {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(retryCodeButtonTitle)
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                    }
                    .buttonStyle(.borderless)
                    .tint(DSColor.primary)
                    .disabled(viewModel.isSendingCode || !viewModel.canSendCode)
                }
            } header: {
                Text(localizedString("bindEmail.email"))
            } footer: {
                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                DSButton(
                    title: localizedString("bindEmail.bind"),
                    icon: "envelope.badge.person.crop",
                    isLoading: viewModel.submitState.isSubmitting
                ) {
                    Task { await viewModel.bind() }
                }
                .dsActionRow()
            }

            if viewModel.status.isBound {
                Section {
                    Button(role: .destructive) {
                        showUnbindConfirmation = true
                    } label: {
                        Label(localizedString("bindEmail.unbind"), systemImage: "envelope.open.fill")
                            .foregroundStyle(DSColor.danger)
                    }
                }
            }
        }
        .dsForm()
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
        LabeledContent(title, value: value)
            .foregroundStyle(DSColor.title)
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
