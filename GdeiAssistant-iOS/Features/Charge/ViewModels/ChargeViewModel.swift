import Foundation

@MainActor
final class ChargeViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var password: String = ""
    @Published var cardInfo: CampusCardInfo?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var paymentSession: ChargePayment?

    private let repository: any ChargeRepository
    private var hasLoaded = false

    var balanceText: String {
        cardInfo.map { String(format: "%.2f", $0.balance) } ?? "—"
    }

    var cardNumber: String {
        cardInfo?.cardNumber ?? "—"
    }

    var canSubmit: Bool {
        guard let value = Int(amount), (1...500).contains(value) else { return false }
        return !password.isEmpty && !isSubmitting && !isLoading
    }

    init(repository: any ChargeRepository) {
        self.repository = repository
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        Task { await loadCardInfo() }
    }

    func refresh() {
        Task { await loadCardInfo() }
    }

    func submitCharge() {
        guard let value = Int(amount), (1...500).contains(value) else {
            errorMessage = NSLocalizedString("charge.amountRange", comment: "")
            return
        }
        guard !password.isEmpty else {
            errorMessage = NSLocalizedString("charge.passwordEmpty", comment: "")
            return
        }
        Task {
            isSubmitting = true
            errorMessage = nil
            do {
                let payment = try await repository.submitCharge(amount: value, password: password)
                paymentSession = payment
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    func clearPaymentSession() {
        paymentSession = nil
    }

    private func loadCardInfo() async {
        isLoading = true
        errorMessage = nil
        do {
            let dashboard = try await repository.fetchCardInfo()
            cardInfo = dashboard.info
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
