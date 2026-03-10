import Foundation

@MainActor
protocol ReadingRepository {
    func fetchReadings() async throws -> [ReadingItem]
}

@MainActor
final class SwitchingReadingRepository: ReadingRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any ReadingRepository
    private let mockRepository: any ReadingRepository

    init(environment: AppEnvironment, remoteRepository: any ReadingRepository, mockRepository: any ReadingRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchReadings() async throws -> [ReadingItem] {
        try await currentRepository.fetchReadings()
    }

    private var currentRepository: any ReadingRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
