import Foundation

@MainActor
protocol ChargeRepository {
    func fetchCardInfo() async throws -> CampusCardDashboard
    func submitCharge(amount: Int, password: String) async throws -> ChargePayment
}

@MainActor
final class SwitchingChargeRepository: ChargeRepository {
    private let environment: AppEnvironment
    private let remoteRepository: RemoteChargeRepository
    private let mockRepository: MockChargeRepository

    init(environment: AppEnvironment, remoteRepository: RemoteChargeRepository, mockRepository: MockChargeRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    private var active: any ChargeRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }

    func fetchCardInfo() async throws -> CampusCardDashboard { try await active.fetchCardInfo() }
    func submitCharge(amount: Int, password: String) async throws -> ChargePayment { try await active.submitCharge(amount: amount, password: password) }
}
