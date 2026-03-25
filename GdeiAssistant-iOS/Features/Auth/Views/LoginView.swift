import SwiftUI

private struct LanguageOption: Identifiable {
    let code: String
    let nativeName: String
    var id: String { code }
}

private let loginLanguageOptions = [
    LanguageOption(code: "zh-CN", nativeName: "简体中文"),
    LanguageOption(code: "zh-HK", nativeName: "繁體中文（香港）"),
    LanguageOption(code: "zh-TW", nativeName: "繁體中文（台灣）"),
    LanguageOption(code: "en", nativeName: "English"),
    LanguageOption(code: "ja", nativeName: "日本語"),
    LanguageOption(code: "ko", nativeName: "한국어")
]

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var environment: AppEnvironment

    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [DSColor.background, DSColor.primary.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        form
                        privacyNote
                        devPanel
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(DSColor.primary)

            Text(AppConstants.Brand.shortDisplayName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(DSColor.title)

            Text(AppConstants.Brand.displayName)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.top, 20)
    }

    private var form: some View {
        DSCard {
            VStack(spacing: 16) {
                DSInputField(
                    title: localizedString("login.account"),
                    placeholder: localizedString("login.accountPlaceholder"),
                    text: $viewModel.username,
                    textContentType: .username
                )

                DSInputField(
                    title: localizedString("login.password"),
                    placeholder: localizedString("login.passwordPlaceholder"),
                    text: $viewModel.password,
                    isSecureEntry: $viewModel.isPasswordSecure,
                    textContentType: .password
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSButton(
                    title: localizedString("login.submit"),
                    icon: "arrow.right.circle.fill",
                    variant: .primary,
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.canSubmit
                ) {
                    Task {
                        await viewModel.login()
                    }
                }

                if viewModel.shouldShowMockHint {
                    Text(AppConstants.Debug.mockCredentialsHint)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var privacyNote: some View {
        Text(LocalizedStringKey("login.privacyNote"))
            .font(.footnote)
            .foregroundStyle(DSColor.subtitle)
            .lineSpacing(4)
            .padding(.horizontal, 4)
    }

    private var devPanel: some View {
        VStack(spacing: 12) {
            // Language selector (always visible)
            DSCard {
                HStack {
                    Text(LocalizedStringKey("appearance.language.label"))
                        .font(.subheadline)
                        .foregroundStyle(DSColor.title)
                    Spacer()
                    Menu {
                        ForEach(loginLanguageOptions) { option in
                            Button {
                                preferences.selectedLocale = option.code
                            } label: {
                                HStack {
                                    Text(option.nativeName)
                                    if preferences.selectedLocale == option.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(loginLanguageOptions.first(where: { $0.code == preferences.selectedLocale })?.nativeName ?? preferences.selectedLocale)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }
                }
            }

            // Mock toggle (debug builds only)
            if environment.isDebug {
                DSCard {
                    VStack(spacing: 8) {
                        Toggle(isOn: Binding(
                            get: { preferences.useMockData },
                            set: { preferences.setUseMockData($0) }
                        )) {
                            Text(LocalizedStringKey("settings.useMockData"))
                                .font(.subheadline)
                                .foregroundStyle(DSColor.title)
                        }

                        if preferences.useMockData {
                            Text(AppConstants.Debug.mockCredentialsHint)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return LoginView(viewModel: LoginViewModel(authManager: container.authManager))
        .environmentObject(container.userPreferences)
        .environmentObject(container.environment)
}
