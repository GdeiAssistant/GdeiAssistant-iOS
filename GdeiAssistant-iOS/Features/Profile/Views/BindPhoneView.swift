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
                    infoRow("当前状态", viewModel.status.isBound ? "已绑定" : "未绑定")
                    if let username = viewModel.status.username {
                        infoRow("绑定账号", username)
                    }
                    if let countryCode = viewModel.status.countryCode {
                        infoRow("当前区号", "+\(countryCode)")
                    }
                    infoRow("当前号码", viewModel.status.maskedValue)
                    Text(viewModel.status.note)
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                }

                DSCard {
                    Picker("国际区号", selection: $viewModel.selectedAreaCode) {
                        ForEach(viewModel.attributions) { item in
                            Text(item.displayText).tag(item.code)
                        }
                    }

                    DSInputField(title: "手机号", placeholder: "请输入手机号", text: $viewModel.phone, keyboardType: .numberPad)
                    DSInputField(title: "验证码", placeholder: "请输入短信验证码", text: $viewModel.randomCode, keyboardType: .numberPad)

                    DSButton(
                        title: viewModel.countdown > 0 ? "\(viewModel.countdown)s 后重试" : "获取验证码",
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
                    title: "绑定手机号",
                    icon: "phone.badge.plus",
                    isLoading: viewModel.submitState.isSubmitting
                ) {
                    Task { await viewModel.bind() }
                }

                if viewModel.status.isBound {
                    DSButton(title: "解绑手机号", icon: "phone.down.fill", variant: .destructive) {
                        showUnbindConfirmation = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle("绑定手机号")
        .task {
            await viewModel.load()
        }
        .confirmationDialog("确认解绑手机号？", isPresented: $showUnbindConfirmation, titleVisibility: .visible) {
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
