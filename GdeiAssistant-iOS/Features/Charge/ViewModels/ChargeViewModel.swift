import Combine
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
    @Published var latestOrder: ChargeOrder?
    @Published var recentOrders: [ChargeOrder] = []
    @Published var isLoadingOrders = false
    @Published var orderErrorMessage: String?

    private let repository: any ChargeRepository
    private var hasLoaded = false
    private let recentOrderLimit = 5

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
        Task { await refreshContent() }
    }

    func refresh() {
        Task { await refreshContent() }
    }

    func submitCharge() {
        Task { await submitChargeRequest() }
    }

    func refreshChargeOrders() {
        Task { await loadRecentOrders() }
    }

    func clearPaymentSession() {
        paymentSession = nil
    }

    func refreshContent() async {
        await loadCardInfo()
        await loadRecentOrders()
    }

    func submitChargeRequest() async {
        guard let value = Int(amount), (1...500).contains(value) else {
            errorMessage = localizedString("charge.amountRange")
            return
        }
        guard !password.isEmpty else {
            errorMessage = localizedString("charge.passwordEmpty")
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            let payment = try await repository.submitCharge(amount: value, password: password)
            paymentSession = payment
            if let order = payment.order {
                latestOrder = order
                recentOrders = upsertRecentOrder(order, in: recentOrders)
                orderErrorMessage = nil
            }
        } catch {
            errorMessage = localizedString("charge.submitFailed")
        }
        isSubmitting = false
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

    private func loadRecentOrders() async {
        isLoadingOrders = true
        orderErrorMessage = nil
        do {
            let orders = try await repository.fetchRecentChargeOrders(
                page: 0,
                size: recentOrderLimit,
                status: nil
            )
            recentOrders = orders
            latestOrder = resolveLatestOrder(current: latestOrder, orders: orders)
        } catch {
            orderErrorMessage = localizedString("charge.order.loadFailed")
        }
        isLoadingOrders = false
    }

    private func upsertRecentOrder(_ order: ChargeOrder, in current: [ChargeOrder]) -> [ChargeOrder] {
        guard let orderId = order.orderId?.trimmingCharacters(in: .whitespacesAndNewlines), !orderId.isEmpty else {
            return Array(([order] + current).prefix(recentOrderLimit))
        }
        let filtered = current.filter { $0.orderId != orderId }
        return Array(([order] + filtered).prefix(recentOrderLimit))
    }

    private func resolveLatestOrder(current: ChargeOrder?, orders: [ChargeOrder]) -> ChargeOrder? {
        guard let orderId = current?.orderId?.trimmingCharacters(in: .whitespacesAndNewlines), !orderId.isEmpty else {
            return orders.first ?? current
        }
        return orders.first { $0.orderId == orderId } ?? current
    }
}
