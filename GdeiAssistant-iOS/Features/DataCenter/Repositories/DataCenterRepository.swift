import Foundation

@MainActor
protocol DataCenterRepository {
    func queryElectricity(_ query: ElectricityQuery) async throws -> ElectricityBill
    func fetchYellowPages() async throws -> [YellowPageCategory]
}

@MainActor
final class SwitchingDataCenterRepository: DataCenterRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any DataCenterRepository
    private let mockRepository: any DataCenterRepository

    init(environment: AppEnvironment, remoteRepository: any DataCenterRepository, mockRepository: any DataCenterRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func queryElectricity(_ query: ElectricityQuery) async throws -> ElectricityBill {
        try await currentRepository.queryElectricity(query)
    }

    func fetchYellowPages() async throws -> [YellowPageCategory] {
        try await currentRepository.fetchYellowPages()
    }

    private var currentRepository: any DataCenterRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
