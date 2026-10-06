import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var environment: AppEnvironment

    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EmptyView()
                } header: {
                    VStack(spacing: DSSpacing.sm) {
                        Image(systemName: "graduationcap.fill")
                            .font(.largeTitle)
                            .foregroundStyle(DSColor.primary)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)

                        Text(AppConstants.Brand.shortDisplayName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(DSColor.title)
                            .accessibilityAddTraits(.isHeader)

                        Text(AppConstants.Brand.displayName)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DSSpacing.md)
                    .textCase(nil)
                }

                Section {
                    DSInputField(
                        title: localizedString("login.account"),
                        placeholder: localizedString("login.accountPlaceholder"),
                        text: $viewModel.username,
                        accessibilityIdentifier: "login.username",
                        textContentType: .username
                    )

                    DSInputField(
                        title: localizedString("login.password"),
                        placeholder: localizedString("login.passwordPlaceholder"),
                        text: $viewModel.password,
                        isSecureEntry: $viewModel.isPasswordSecure,
                        accessibilityIdentifier: "login.password",
                        textContentType: .password
                    )
                } header: {
                    Text(LocalizedStringKey("login.account"))
                }

                if viewModel.requiresCampusCredentialConsent {
                    Section {
                        Toggle(isOn: $viewModel.campusCredentialConsentChecked) {
                            Text(localizedString("login.campusCredentialConsentText"))
                                .font(.footnote)
                                .foregroundStyle(DSColor.title)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tint(DSColor.primary)
                        .disabled(viewModel.isLoading)
                        .accessibilityIdentifier("login.campusCredentialConsent")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                Section {
                    DSButton(
                        title: localizedString("login.submit"),
                        variant: .primary,
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.canSubmit,
                        accessibilityIdentifier: "login.submit"
                    ) {
                        Task {
                            await viewModel.login()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    if viewModel.shouldShowMockHint {
                        Text(localizedString("login.mockCredentialsHint"))
                            .font(.caption)
                            .foregroundStyle(DSColor.tertiaryText)
                    }
                }

                Section {
                    Text(LocalizedStringKey("login.privacyNote"))
                        .font(.footnote)
                        .foregroundStyle(DSColor.tertiaryText)
                }

                if environment.isDebug {
                    Section {
                        Toggle(isOn: Binding(
                            get: { preferences.useMockData },
                            set: { newValue in
                                preferences.setUseMockData(newValue)
                                environment.updateDataSourceMode(newValue ? .mock : .remote)
                            }
                        )) {
                            Text(LocalizedStringKey("settings.useMockData"))
                        }
                        .tint(DSColor.primary)
                        .accessibilityIdentifier("login.mock.toggle")

                        if preferences.useMockData {
                            Text(localizedString("login.mockCredentialsHint"))
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                                .accessibilityIdentifier("login.mock.hint")
                        }
                    }
                }
            }
            .dsListBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenuButton
                }
            }
        }
    }

    private var languageMenuButton: some View {
        Menu {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    preferences.selectedLocale = option.localeIdentifier
                } label: {
                    HStack {
                        Text(option.nativeName)
                        if preferences.selectedLocale == option.localeIdentifier {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "globe")
        }
        .accessibilityLabel(Text(LocalizedStringKey("appearance.language.label")))
    }
}

#Preview {
    let container = AppContainer.preview
    return LoginView(viewModel: LoginViewModel(authManager: container.authManager))
        .environmentObject(container.userPreferences)
        .environmentObject(container.environment)
}
