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

@MainActor
final class SwitchingDeliveryRepository: DeliveryRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any DeliveryRepository
    private let mockRepository: any DeliveryRepository

    init(environment: AppEnvironment, remoteRepository: any DeliveryRepository, mockRepository: any DeliveryRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchOrders(start: Int, size: Int) async throws -> [DeliveryOrder] {
        try await currentRepository.fetchOrders(start: start, size: size)
    }

    func fetchMine() async throws -> DeliveryMineSummary {
        try await currentRepository.fetchMine()
    }

    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail {
        try await currentRepository.fetchDetail(orderID: orderID)
    }

    func publish(draft: DeliveryDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func accept(orderID: String) async throws {
        try await currentRepository.accept(orderID: orderID)
    }

    func finishTrade(tradeID: String) async throws {
        try await currentRepository.finishTrade(tradeID: tradeID)
    }

    private var currentRepository: any DeliveryRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
