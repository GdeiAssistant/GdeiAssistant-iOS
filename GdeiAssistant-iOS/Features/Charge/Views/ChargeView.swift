import SwiftUI

struct ChargeView: View {
    @ObservedObject var viewModel: ChargeViewModel

    var body: some View {
        Group {
            if let session = viewModel.paymentSession {
                PaymentWebView(
                    session: session,
                    order: viewModel.latestOrder,
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
        ScrollView {
            VStack(spacing: 20) {
                overviewCard
                if let order = viewModel.latestOrder {
                    chargeOrderStatusCard(order)
                }
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
                recentOrdersSection
            }
            .padding()
        }
        .refreshable { viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.cardInfo == nil {
                ProgressView(NSLocalizedString("charge.loading", comment: ""))
            }
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.cardInfo?.ownerName ?? NSLocalizedString("charge.fallbackUser", comment: ""))
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1), in: Capsule())

            Text(NSLocalizedString("charge.subtitle", comment: ""))
                .font(.title2.bold())

            HStack(spacing: 12) {
                metricCard(label: NSLocalizedString("charge.currentBalance", comment: ""), value: viewModel.balanceText)
                metricCard(label: NSLocalizedString("charge.cardStatus", comment: ""), value: viewModel.cardInfo?.status.displayName ?? "—")
            }
            HStack(spacing: 12) {
                metricCard(label: NSLocalizedString("charge.cardNumber", comment: ""), value: viewModel.cardNumber)
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
            Text(NSLocalizedString("charge.inputTitle", comment: "")).font(.headline)
            Text(NSLocalizedString("charge.quickAmount", comment: "")).font(.caption).foregroundStyle(.secondary)

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

            TextField(NSLocalizedString("charge.amountHint", comment: ""), text: $viewModel.amount)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("charge.passwordLabel", comment: "")).font(.caption).foregroundStyle(.secondary)
            SecureField(NSLocalizedString("charge.passwordHint", comment: ""), text: $viewModel.password)
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
                Text(viewModel.isSubmitting ? NSLocalizedString("charge.processing", comment: "") : NSLocalizedString("charge.submit", comment: ""))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canSubmit)
    }

    private func chargeOrderStatusCard(_ order: ChargeOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(localizedString("charge.order.statusTitle"))
                    .font(.headline)
                Spacer()
                statusBadge(order)
            }

            Text(order.localizedStatusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            orderMetaRows(order)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedString("charge.order.recentTitle"))
                        .font(.headline)
                    Text(localizedString("charge.order.recentHint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    viewModel.refreshChargeOrders()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoadingOrders)
                .accessibilityLabel(localizedString("charge.order.refresh"))
            }

            if viewModel.isLoadingOrders && viewModel.recentOrders.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else if let error = viewModel.orderErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if viewModel.recentOrders.isEmpty {
                Text(localizedString("charge.order.empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentOrders) { order in
                        chargeOrderRow(order)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func chargeOrderRow(_ order: ChargeOrder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(orderTitle(order))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                statusBadge(order)
            }

            Text(order.localizedStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            orderMetaRows(order)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func orderMetaRows(_ order: ChargeOrder) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(orderAmountText(order), systemImage: "yensign.circle")
                Spacer()
                Label(orderUpdatedText(order), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let retryAfter = order.retryAfter, retryAfter > 0 {
                Text(String(format: localizedString("charge.order.retryAfter"), retryAfter))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            return .blue
        case "PROCESSING", "CREATED":
            return .orange
        case "FAILED":
            return .red
        case "MANUAL_REVIEW", "UNKNOWN":
            return .purple
        default:
            return .secondary
        }
    }
}
