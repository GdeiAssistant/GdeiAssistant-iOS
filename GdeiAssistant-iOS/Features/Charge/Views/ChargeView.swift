import SwiftUI

struct ChargeView: View {
    @ObservedObject var viewModel: ChargeViewModel

    var body: some View {
        Group {
            if viewModel.paymentSession != nil {
                PaymentWebView(
                    session: viewModel.paymentSession!,
                    onDismiss: { viewModel.clearPaymentSession() }
                )
            } else {
                chargeForm
            }
        }
        .navigationTitle("校园卡充值")
        .onAppear { viewModel.loadIfNeeded() }
    }

    private var chargeForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewCard
                amountSection
                passwordSection
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                submitButton
            }
            .padding()
        }
        .refreshable { viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.cardInfo == nil {
                ProgressView("加载中…")
            }
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.cardInfo?.ownerName ?? "校园卡用户")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1), in: Capsule())

            Text("校园卡充值")
                .font(.title2.bold())

            HStack(spacing: 12) {
                metricCard(label: "当前余额", value: viewModel.balanceText)
                metricCard(label: "卡状态", value: viewModel.cardInfo?.status.displayName ?? "—")
            }
            HStack(spacing: 12) {
                metricCard(label: "卡号", value: viewModel.cardNumber)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metricCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("充值信息").font(.headline)
            Text("常用金额").font(.caption).foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(["20", "50", "100", "200"], id: \.self) { preset in
                    Button {
                        viewModel.amount = preset
                    } label: {
                        Text(preset)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.amount == preset ? .blue : .secondary)
                }
            }

            TextField("充值金额（1–500 元）", text: $viewModel.amount)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("身份验证").font(.caption).foregroundStyle(.secondary)
            SecureField("账号密码", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var submitButton: some View {
        Button {
            viewModel.submitCharge()
        } label: {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "creditcard")
                }
                Text(viewModel.isSubmitting ? "正在提交充值请求…" : "提交充值")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canSubmit)
    }
}
