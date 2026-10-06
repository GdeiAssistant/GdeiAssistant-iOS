import SwiftUI

struct BindPhoneView: View {
    @StateObject private var viewModel: BindPhoneViewModel
    @State private var showUnbindConfirmation = false
    @State private var showAreaCodePicker = false

    init(viewModel: BindPhoneViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                infoRow(localizedString("bindPhone.status"), viewModel.status.isBound ? localizedString("bindPhone.bound") : localizedString("bindPhone.unbound"))
                if let username = viewModel.status.username {
                    infoRow(localizedString("bindPhone.account"), username)
                }
                if let countryCode = viewModel.status.countryCode {
                    infoRow(localizedString("bindPhone.areaCode"), "+\(countryCode)")
                }
                infoRow(localizedString("bindPhone.currentNumber"), viewModel.status.maskedValue)
            } footer: {
                Text(viewModel.status.note)
            }

            Section {
                Button {
                    showAreaCodePicker = true
                } label: {
                    HStack(spacing: DSSpacing.sm) {
                        Text(localizedString("bindPhone.intlCode"))
                            .foregroundStyle(DSColor.title)

                        Spacer(minLength: DSSpacing.xs)

                        Text(selectedAreaCodeText)
                            .foregroundStyle(DSColor.subtitle)
                            .multilineTextAlignment(.trailing)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote)
                            .foregroundStyle(DSColor.tertiaryText)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                DSInputField(title: localizedString("bindPhone.phone"), placeholder: localizedString("bindPhone.phonePlaceholder"), text: $viewModel.phone, keyboardType: .numberPad)

                HStack(spacing: DSSpacing.sm) {
                    DSInputField(title: localizedString("bindPhone.code"), placeholder: localizedString("bindPhone.codePlaceholder"), text: $viewModel.randomCode, keyboardType: .numberPad)
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
                Text(localizedString("bindPhone.phone"))
            } footer: {
                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                DSButton(
                    title: localizedString("bindPhone.bind"),
                    icon: "phone.badge.plus",
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
                        Label(localizedString("bindPhone.unbind"), systemImage: "phone.down.fill")
                            .foregroundStyle(DSColor.danger)
                    }
                }
            }
        }
        .dsForm()
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
        .dsListBackground()
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
