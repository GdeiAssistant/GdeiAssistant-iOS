import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

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
}

#Preview {
    let container = AppContainer.preview
    return LoginView(viewModel: LoginViewModel(authManager: container.authManager))
}
