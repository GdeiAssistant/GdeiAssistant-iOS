import Foundation

@MainActor
protocol SpareRepository {
    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem]
}

@MainActor
final class SwitchingSpareRepository: SpareRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any SpareRepository
    private let mockRepository: any SpareRepository

    init(environment: AppEnvironment, remoteRepository: any SpareRepository, mockRepository: any SpareRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem] {
        try await currentRepository.queryRooms(query)
    }

    private var currentRepository: any SpareRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
