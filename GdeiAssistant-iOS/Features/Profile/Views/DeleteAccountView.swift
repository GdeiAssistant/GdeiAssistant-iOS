import SwiftUI

struct DeleteAccountView: View {
    @StateObject private var viewModel: DeleteAccountViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var showConfirmation = false

    init(viewModel: DeleteAccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    Label("注销后以下数据将被永久删除", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(DSColor.danger)

                    riskRow("账号及个人资料将被清空")
                    riskRow("表白墙、话题、跑腿等发布内容将被删除")
                    riskRow("评论、点赞、互动记录将被清除")
                    riskRow("自定义课程与已保存证件信息会被删除")
                    riskRow("绑定的手机号和邮箱会被解绑")
                }

                DSCard {
                    SecureFormField(title: "账号密码", placeholder: "请输入当前账号密码", text: $viewModel.password)

                    Toggle("我已知晓以上风险并确认注销", isOn: $viewModel.agreed)

                    if case .failure(let message) = viewModel.submitState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: "确认注销账号",
                    icon: "person.crop.circle.badge.xmark",
                    variant: .destructive,
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: !viewModel.canSubmit
                ) {
                    showConfirmation = true
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle("注销账号")
        .confirmationDialog("确认执行不可逆的账号注销？", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("继续注销", role: .destructive) {
                Task {
                    await viewModel.submit()
                    if case .success = viewModel.submitState {
                        await container.authManager.logout()
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("系统会先校验密码和账号状态，成功后将清除本地登录态。")
        }
    }

    private func riskRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(DSColor.danger)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
    }
}
