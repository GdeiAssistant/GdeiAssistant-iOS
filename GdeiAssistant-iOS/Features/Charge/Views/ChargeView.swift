import SwiftUI

struct ChargeView: View {
    @ObservedObject var viewModel: ChargeViewModel

    var body: some View {
        Group {
            if let session = viewModel.paymentSession {
                PaymentWebView(
                    session: session,
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
}
