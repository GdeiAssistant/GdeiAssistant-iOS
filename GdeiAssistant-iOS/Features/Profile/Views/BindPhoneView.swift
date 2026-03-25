import SwiftUI

struct BindPhoneView: View {
    @StateObject private var viewModel: BindPhoneViewModel
    @State private var showUnbindConfirmation = false

    init(viewModel: BindPhoneViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    infoRow(localizedString("bindPhone.status"), viewModel.status.isBound ? localizedString("bindPhone.bound") : localizedString("bindPhone.unbound"))
                    if let username = viewModel.status.username {
                        infoRow(localizedString("bindPhone.account"), username)
                    }
                    if let countryCode = viewModel.status.countryCode {
                        infoRow(localizedString("bindPhone.areaCode"), "+\(countryCode)")
                    }
                    infoRow(localizedString("bindPhone.currentNumber"), viewModel.status.maskedValue)
                    Text(viewModel.status.note)
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                }

                DSCard {
                    Picker(localizedString("bindPhone.intlCode"), selection: $viewModel.selectedAreaCode) {
                        ForEach(viewModel.attributions) { item in
                            Text(item.displayText).tag(item.code)
                        }
                    }

                    DSInputField(title: localizedString("bindPhone.phone"), placeholder: localizedString("bindPhone.phonePlaceholder"), text: $viewModel.phone, keyboardType: .numberPad)
                    DSInputField(title: localizedString("bindPhone.code"), placeholder: localizedString("bindPhone.codePlaceholder"), text: $viewModel.randomCode, keyboardType: .numberPad)

                    DSButton(
                        title: retryCodeButtonTitle,
                        icon: "message.badge",
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
                    title: localizedString("bindPhone.bind"),
                    icon: "phone.badge.plus",
                    isLoading: viewModel.submitState.isSubmitting
                ) {
                    Task { await viewModel.bind() }
                }

                if viewModel.status.isBound {
                    DSButton(title: localizedString("bindPhone.unbind"), icon: "phone.down.fill", variant: .destructive) {
                        showUnbindConfirmation = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle(localizedString("bindPhone.title"))
        .task {
            await viewModel.load()
        }
        .confirmationDialog(localizedString("bindPhone.confirmUnbind"), isPresented: $showUnbindConfirmation, titleVisibility: .visible) {
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
