import SwiftUI

struct CardView: View {
    @StateObject private var viewModel: CardViewModel
    @State private var showLossConfirm = false
    @State private var showPasswordSheet = false
    @State private var cardPassword = ""

    init(viewModel: CardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.dashboard == nil {
                DSLoadingView(text: "正在加载校园卡...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.dashboard == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadDashboard() }
                }
            } else if let dashboard = viewModel.dashboard {
                content(dashboard)
            } else {
                DSEmptyStateView(icon: "creditcard", title: "暂无校园卡信息", message: "请稍后重试")
            }
        }
        .navigationTitle("校园卡")
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("确认挂失", isPresented: $showLossConfirm) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) {
                showPasswordSheet = true
            }
        } message: {
            Text("挂失后将暂停校园卡消费功能，是否继续进行安全验证？")
        }
        .sheet(isPresented: $showPasswordSheet, onDismiss: resetPasswordInput) {
            PasswordInputSheet(
                title: "校园卡挂失",
                message: "请输入校园卡查询密码完成高风险操作验证。为保护账户安全，密码不会被本地保存。",
                placeholder: "请输入校园卡查询密码",
                confirmTitle: "确认挂失",
                keyboardType: .numberPad,
                isSubmitting: viewModel.submitState.isSubmitting,
                errorMessage: {
                    if case .failure(let message) = viewModel.submitState { return message }
                    return nil
                }(),
                password: $cardPassword,
                onCancel: {
                    showPasswordSheet = false
                },
                onConfirm: {
                    Task { await submitLossRequest() }
                }
            )
            .presentationDetents([.medium])
        }
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = viewModel.submitState {
                    return true
                }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearSubmitState()
                }
            }
        )) {
            Button("知道了") {
                viewModel.clearSubmitState()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }

    private func content(_ dashboard: CampusCardDashboard) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                DSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("校园卡余额")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)

                        Text("¥\(dashboard.info.balance, specifier: "%.2f")")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(DSColor.title)

                        HStack {
                            Text("卡号 \(dashboard.info.cardNumber)")
                            Spacer()
                            Text("状态：\(dashboard.info.status.displayName)")
                        }
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                    }
                }

                DSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("消费记录")
                            .font(.headline)
                            .foregroundStyle(DSColor.title)

                        DatePicker(
                            "查询日期",
                            selection: $viewModel.selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        DSButton(title: "查询当天消费记录", icon: "calendar") {
                            Task { await viewModel.loadDashboard(for: viewModel.selectedDate) }
                        }
                        .disabled(viewModel.isLoading)

                        Text("当前查看：\(viewModel.selectedDateText)")
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                    }
                }

                DSCard {
                    Text("安全操作")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Text("挂失前需要输入校园卡查询密码进行验证。该密码仅用于本次提交，不会写入本地存储。")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(4)

                    DSButton(
                        title: dashboard.info.status == .lost ? "已挂失" : "挂失校园卡",
                        icon: "lock.shield",
                        variant: .destructive,
                        isLoading: viewModel.submitState.isSubmitting,
                        isDisabled: dashboard.info.status == .lost
                    ) {
                        showLossConfirm = true
                    }
                }

                DSCard {
                    Text("\(viewModel.selectedDateText) 消费记录")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    if dashboard.transactions.isEmpty {
                        Text("这一天没有查询到消费记录")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        ForEach(dashboard.transactions) { transaction in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(transaction.merchantName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DSColor.title)
                                    Text("\(transaction.timeText) · \(transaction.category)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                Spacer()
                                Text(String(format: "-¥%.2f", transaction.amount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.danger)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.loadDashboard()
        }
    }

    private func submitLossRequest() async {
        await viewModel.reportLoss(cardPassword: cardPassword)
        if case .success = viewModel.submitState {
            showPasswordSheet = false
            resetPasswordInput()
        }
    }

    private func resetPasswordInput() {
        cardPassword = ""
    }
}

#Preview {
    NavigationStack {
        CardView(viewModel: CardViewModel(repository: MockCardRepository()))
    }
}
