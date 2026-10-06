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
                DSLoadingView(text: localizedString("card.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.dashboard == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadDashboard() }
                }
            } else if let dashboard = viewModel.dashboard {
                content(dashboard)
            } else {
                DSEmptyStateView(icon: "creditcard", title: localizedString("card.emptyTitle"), message: localizedString("card.emptyMessage"))
            }
        }
        .navigationTitle(localizedString("card.title"))
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(localizedString("card.confirmLoss"), isPresented: $showLossConfirm) {
            Button(localizedString("common.cancel"), role: .cancel) {}
            Button(localizedString("common.confirm"), role: .destructive) {
                showPasswordSheet = true
            }
        } message: {
            Text(localizedString("card.confirmLossMessage"))
        }
        .sheet(isPresented: $showPasswordSheet, onDismiss: resetPasswordInput) {
            PasswordInputSheet(
                title: localizedString("card.lossSheetTitle"),
                message: localizedString("card.lossSheetMessage"),
                placeholder: localizedString("card.lossSheetPlaceholder"),
                confirmTitle: localizedString("card.lossSheetConfirm"),
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
        .alert(localizedString("card.notice"), isPresented: Binding(
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
            Button(localizedString("card.understood")) {
                viewModel.clearSubmitState()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }

    private func content(_ dashboard: CampusCardDashboard) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(LocalizedStringKey("card.balance"))
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)

                    Text("\u{00A5}\(dashboard.info.balance, specifier: "%.2f")")
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(DSColor.title)

                    HStack {
                        Text(String(format: localizedString("card.number"), dashboard.info.cardNumber))
                        Spacer()
                        DSTag(text: String(format: localizedString("card.status"), dashboard.info.status.displayName))
                    }
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
                }
                .padding(.vertical, DSSpacing.xs)

            }

            Section {
                DatePicker(
                    LocalizedStringKey("card.queryDate"),
                    selection: $viewModel.selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(DSColor.primary)

                Button {
                    Task { await viewModel.loadDashboard(for: viewModel.selectedDate) }
                } label: {
                    Label(localizedString("card.queryButton"), systemImage: "calendar")
                        .foregroundStyle(DSColor.primary)
                }
                .disabled(viewModel.isLoading)
            } header: {
                Text(LocalizedStringKey("card.transactions"))
            } footer: {
                Text(String(format: localizedString("card.currentDate"), viewModel.selectedDateText))
            }

            Section {
                if dashboard.transactions.isEmpty {
                    Text(LocalizedStringKey("card.noTransactions"))
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                } else {
                    ForEach(dashboard.transactions) { transaction in
                        HStack(spacing: DSSpacing.sm) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(transaction.merchantName)
                                    .font(.body)
                                    .foregroundStyle(DSColor.title)
                                Text("\(transaction.timeText) \u{00B7} \(transaction.category)")
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            Spacer()
                            Text(String(format: "-\u{00A5}%.2f", transaction.amount))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(DSColor.title)
                        }
                        .padding(.vertical, DSSpacing.xxs)
                        .accessibilityElement(children: .combine)
                    }
                }
            } header: {
                Text(String(format: localizedString("card.dateTransactions"), viewModel.selectedDateText))
            }

            Section {
                DSButton(
                    title: dashboard.info.status == .lost ? localizedString("card.alreadyLost") : localizedString("card.reportLoss"),
                    icon: "lock.shield",
                    variant: .destructive,
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: dashboard.info.status == .lost
                ) {
                    showLossConfirm = true
                }
                .dsActionRow()
            } header: {
                Text(LocalizedStringKey("card.security"))
            } footer: {
                Text(LocalizedStringKey("card.securityNote"))
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
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
