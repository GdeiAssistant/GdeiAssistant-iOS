import Foundation

@MainActor
protocol DeliveryRepository {
    func fetchOrders(start: Int, size: Int) async throws -> [DeliveryOrder]
    func fetchMine() async throws -> DeliveryMineSummary
    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail
    func publish(draft: DeliveryDraft) async throws
    func accept(orderID: String) async throws
    func finishTrade(tradeID: String) async throws
}
