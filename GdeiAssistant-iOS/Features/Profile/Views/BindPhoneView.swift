import SwiftUI

struct BindPhoneView: View {
    @StateObject private var viewModel: BindPhoneViewModel
    @State private var showUnbindConfirmation = false
    @State private var showAreaCodePicker = false

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
                    Button {
                        showAreaCodePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizedString("bindPhone.intlCode"))
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)

                                Text(selectedAreaCodeText)
                                    .foregroundStyle(DSColor.title)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

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
        .sheet(isPresented: $showAreaCodePicker) {
            NavigationStack {
                BindPhoneAreaCodePickerView(
                    attributions: viewModel.attributions,
                    selectedAreaCode: viewModel.selectedAreaCode
                ) { selectedCode in
                    viewModel.selectedAreaCode = selectedCode
                }
            }
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

    private var selectedAreaCodeText: String {
        viewModel.selectedAttribution?.displayText
            ?? "+\(viewModel.selectedAreaCode)"
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

private struct BindPhoneAreaCodePickerView: View {
    @Environment(\.dismiss) private var dismiss

    let attributions: [PhoneAttribution]
    let selectedAreaCode: Int
    let onSelect: (Int) -> Void

    @State private var searchText = ""

    var body: some View {
        List(filteredAttributions) { attribution in
            Button {
                onSelect(attribution.code)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attribution.displayName())
                            .foregroundStyle(DSColor.title)
                        Text("+\(attribution.code)")
                            .font(.footnote)
                            .foregroundStyle(DSColor.subtitle)
                    }

                    Spacer()

                    Text(attribution.flag)
                        .font(.title3)

                    if attribution.code == selectedAreaCode {
                        Image(systemName: "checkmark")
                            .foregroundStyle(DSColor.primary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $searchText)
        .navigationTitle(localizedString("bindPhone.intlCode"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(localizedString("common.cancel")) {
                    dismiss()
                }
            }
        }
    }

    private var filteredAttributions: [PhoneAttribution] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return attributions }

        let normalizedQuery = query.lowercased()
        let codeQuery = normalizedQuery.replacingOccurrences(of: "+", with: "")

        return attributions.filter { attribution in
            attribution.displayName().lowercased().contains(normalizedQuery)
                || attribution.name.lowercased().contains(normalizedQuery)
                || String(attribution.code).contains(codeQuery)
        }
    }
}
