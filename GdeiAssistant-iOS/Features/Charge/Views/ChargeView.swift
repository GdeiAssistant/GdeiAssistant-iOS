import SwiftUI

struct ChargeView: View {
    @ObservedObject var viewModel: ChargeViewModel

    var body: some View {
        Group {
            if let session = viewModel.paymentSession {
                PaymentWebView(
                    session: session,
                    order: session.order,
                    onDismiss: { viewModel.clearPaymentSession() }
                )
            } else {
                chargeForm
            }
        }
        .navigationTitle(NSLocalizedString("charge.title", comment: ""))
        .onAppear { viewModel.loadIfNeeded() }
    }

    private var chargeForm: some View {
        Form {
            overviewCard
            if let order = viewModel.latestOrder {
                chargeOrderStatusCard(order)
            }
            amountSection
            passwordSection
            submitButton
            recentOrdersSection
        }
        .dsForm()
        .refreshable { viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.cardInfo == nil {
                ProgressView(NSLocalizedString("charge.loading", comment: ""))
            }
        }
    }

    private var overviewCard: some View {
        Section {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                DSTag(text: viewModel.cardInfo?.ownerName ?? NSLocalizedString("charge.fallbackUser", comment: ""))

                Text(NSLocalizedString("charge.subtitle", comment: ""))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)
            }
            .padding(.vertical, DSSpacing.xxs)

            metricCard(label: NSLocalizedString("charge.currentBalance", comment: ""), value: viewModel.balanceText)
            metricCard(label: NSLocalizedString("charge.cardStatus", comment: ""), value: viewModel.cardInfo?.status.displayName ?? "—")
            metricCard(label: NSLocalizedString("charge.cardNumber", comment: ""), value: viewModel.cardNumber)
        }
    }

    private func metricCard(label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .monospacedDigit()
                .foregroundStyle(DSColor.subtitle)
        }
        .foregroundStyle(DSColor.title)
    }

    private var amountSection: some View {
        Section {
            HStack(spacing: DSSpacing.xs) {
                ForEach(["20", "50", "100", "200"], id: \.self) { preset in
                    let isSelected = viewModel.amount == preset
                    Button {
                        viewModel.amount = preset
                    } label: {
                        Text(preset)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(isSelected ? DSColor.primary : DSColor.title)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(isSelected ? DSColor.primarySoft : DSColor.fieldBackground, in: DSRadius.controlShape)
                            .overlay(
                                DSRadius.controlShape
                                    .strokeBorder(isSelected ? DSColor.primary : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(DSPressableButtonStyle())
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.vertical, DSSpacing.xxs)

            TextField(NSLocalizedString("charge.amountHint", comment: ""), text: $viewModel.amount)
                .keyboardType(.numberPad)
                .monospacedDigit()
        } header: {
            Text(NSLocalizedString("charge.inputTitle", comment: ""))
        } footer: {
            Text(NSLocalizedString("charge.quickAmount", comment: ""))
        }
    }

    private var passwordSection: some View {
        Section {
            SecureField(NSLocalizedString("charge.passwordHint", comment: ""), text: $viewModel.password)
        } header: {
            Text(NSLocalizedString("charge.passwordLabel", comment: ""))
        } footer: {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(DSColor.danger)
            }
        }
    }

    private var submitButton: some View {
        Section {
            DSButton(
                title: viewModel.isSubmitting ? NSLocalizedString("charge.processing", comment: "") : NSLocalizedString("charge.submit", comment: ""),
                icon: "creditcard",
                isLoading: viewModel.isSubmitting,
                isDisabled: !viewModel.canSubmit
            ) {
                viewModel.submitCharge()
            }
            .dsActionRow()
        }
    }

    private func chargeOrderStatusCard(_ order: ChargeOrder) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(order.localizedStatusMessage)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.title)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: DSSpacing.xs)
                    statusBadge(order)
                }

                orderMetaRows(order)
            }
            .padding(.vertical, DSSpacing.xxs)
        } header: {
            Text(localizedString("charge.order.statusTitle"))
        }
    }

    private var recentOrdersSection: some View {
        Section {
            if viewModel.isLoadingOrders && viewModel.recentOrders.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DSSpacing.xs)
            } else if let error = viewModel.orderErrorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.danger)
            } else if viewModel.recentOrders.isEmpty {
                Text(localizedString("charge.order.empty"))
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
            } else {
                ForEach(viewModel.recentOrders) { order in
                    chargeOrderRow(order)
                }
            }
        } header: {
            HStack(alignment: .center) {
                Text(localizedString("charge.order.recentTitle"))
                Spacer()
                Button {
                    viewModel.refreshChargeOrders()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(DSColor.primary)
                .disabled(viewModel.isLoadingOrders)
                .accessibilityLabel(localizedString("charge.order.refresh"))
            }
        } footer: {
            Text(localizedString("charge.order.recentHint"))
        }
    }

    private func chargeOrderRow(_ order: ChargeOrder) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(orderTitle(order))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                    .lineLimit(1)
                Spacer()
                statusBadge(order)
            }

            Text(order.localizedStatusMessage)
                .font(.footnote)
                .foregroundStyle(DSColor.subtitle)
                .fixedSize(horizontal: false, vertical: true)

            orderMetaRows(order)
        }
        .padding(.vertical, DSSpacing.xxs)
    }

    private func orderMetaRows(_ order: ChargeOrder) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(orderAmountText(order), systemImage: "yensign.circle")
                Spacer()
                Label(orderUpdatedText(order), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(DSColor.subtitle)

            if let retryAfter = order.retryAfter, retryAfter > 0 {
                Text(String(format: localizedString("charge.order.retryAfter"), retryAfter))
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            }
        }
    }

    private func statusBadge(_ order: ChargeOrder) -> some View {
        Text(order.localizedStatusLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(statusTint(order))
            .background(statusTint(order).opacity(0.12), in: Capsule())
    }

    private func orderTitle(_ order: ChargeOrder) -> String {
        if let orderId = order.orderId?.trimmingCharacters(in: .whitespacesAndNewlines), !orderId.isEmpty {
            return String(format: localizedString("charge.order.id"), orderId)
        }
        return localizedString("charge.order.statusTitle")
    }

    private func orderAmountText(_ order: ChargeOrder) -> String {
        guard let amount = order.amount else {
            return "\(localizedString("charge.order.amount")) —"
        }
        return "\(localizedString("charge.order.amount")) \(amount) \(localizedString("charge.currencyUnit"))"
    }

    private func orderUpdatedText(_ order: ChargeOrder) -> String {
        let updatedAt = order.updatedAt ?? order.submittedAt ?? order.createdAt ?? "—"
        return "\(localizedString("charge.order.updated")) \(updatedAt)"
    }

    private func statusTint(_ order: ChargeOrder) -> Color {
        switch order.normalizedStatus {
        case "PAYMENT_SESSION_CREATED":
            return DSColor.primary
        case "PROCESSING", "CREATED", "MANUAL_REVIEW", "UNKNOWN":
            return DSColor.warning
        case "FAILED":
            return DSColor.danger
        default:
            return DSColor.subtitle
        }
    }
}
