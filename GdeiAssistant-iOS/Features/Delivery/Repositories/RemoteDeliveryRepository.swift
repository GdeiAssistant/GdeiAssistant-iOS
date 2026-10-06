import Foundation

@MainActor
final class RemoteDeliveryRepository: DeliveryRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchOrders(start: Int, size: Int) async throws -> [DeliveryOrder] {
        let dtos: [DeliveryOrderRemoteDTO] = try await apiClient.get(
            "/delivery/order/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return try dtos.map(DeliveryRemoteMapper.mapOrder)
    }

    func fetchMine() async throws -> DeliveryMineSummary {
        let dto: DeliveryMineRemoteDTO = try await apiClient.get("/delivery/mine", requiresAuth: true)
        return try DeliveryRemoteMapper.mapMine(dto)
    }

    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail {
        let dto: DeliveryDetailRemoteDTO = try await apiClient.get(
            "/delivery/order/id/\(orderID)",
            requiresAuth: true
        )
        return try DeliveryRemoteMapper.mapDetail(dto)
    }

    func publish(draft: DeliveryDraft) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/delivery/order",
            body: DeliveryRemoteMapper.publishRequest(for: draft),
            requiresAuth: true
        )
    }

    func accept(orderID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/delivery/acceptorder",
            queryItems: [URLQueryItem(name: "orderId", value: orderID)],
            requiresAuth: true
        )
    }

    func finishTrade(tradeID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/delivery/trade/id/\(tradeID)/finishtrade",
            requiresAuth: true
        )
    }
}
