import Foundation

@MainActor
protocol ChargeRepository {
    func fetchCardInfo() async throws -> CampusCardDashboard
    func submitCharge(amount: Int, password: String) async throws -> ChargePayment
    func fetchChargeOrder(orderId: String) async throws -> ChargeOrder
    func fetchRecentChargeOrders(page: Int, size: Int, status: String?) async throws -> [ChargeOrder]
}
