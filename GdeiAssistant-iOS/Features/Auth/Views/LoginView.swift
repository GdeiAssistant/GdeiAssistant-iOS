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
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 56))
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
                    title: "账号",
                    placeholder: "请输入用户名",
                    text: $viewModel.username,
                    textContentType: .username
                )

                DSInputField(
                    title: "密码",
                    placeholder: "请输入密码",
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
                    title: "登录",
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
        Text("登录即表示你同意《用户服务协议》与《隐私政策》。我们仅在提供校园服务时处理必要信息。")
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
