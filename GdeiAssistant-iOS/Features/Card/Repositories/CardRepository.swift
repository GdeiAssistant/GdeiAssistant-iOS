import Foundation

@MainActor
protocol CardRepository {
    func fetchDashboard(on date: Date) async throws -> CampusCardDashboard
    func reportLoss(request: CardLossRequest) async throws
}

@MainActor
final class SwitchingCardRepository: CardRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any CardRepository
    private let mockRepository: any CardRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any CardRepository,
        mockRepository: any CardRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchDashboard(on date: Date) async throws -> CampusCardDashboard {
        try await currentRepository.fetchDashboard(on: date)
    }

    func reportLoss(request: CardLossRequest) async throws {
        try await currentRepository.reportLoss(request: request)
    }

    private var currentRepository: any CardRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
