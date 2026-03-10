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
                    infoRow("当前状态", viewModel.status.isBound ? "已绑定" : "未绑定")
                    infoRow("当前邮箱", viewModel.status.maskedValue)
                }

                DSCard {
                    DSInputField(title: "邮箱地址", placeholder: "请输入邮箱地址", text: $viewModel.email, keyboardType: .emailAddress)
                    DSInputField(title: "验证码", placeholder: "请输入邮箱验证码", text: $viewModel.randomCode, keyboardType: .numberPad)

                    DSButton(
                        title: viewModel.countdown > 0 ? "\(viewModel.countdown)s 后重试" : "获取验证码",
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
                    title: "绑定邮箱",
                    icon: "envelope.badge.person.crop",
                    isLoading: viewModel.submitState.isSubmitting
                ) {
                    Task { await viewModel.bind() }
                }

                if viewModel.status.isBound {
                    DSButton(title: "解绑邮箱", icon: "envelope.open.fill", variant: .destructive) {
                        showUnbindConfirmation = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle("绑定邮箱")
        .task {
            await viewModel.load()
        }
        .confirmationDialog("确认解绑邮箱？", isPresented: $showUnbindConfirmation, titleVisibility: .visible) {
            Button("确认解绑", role: .destructive) {
                Task { await viewModel.unbind() }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button("知道了") { viewModel.submitState = .idle }
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
}
