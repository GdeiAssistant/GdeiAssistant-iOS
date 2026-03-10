import Foundation

@MainActor
final class RemoteReadingRepository: ReadingRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchReadings() async throws -> [ReadingItem] {
        let dtos: [ReadingRemoteDTO] = try await apiClient.get("/reading", requiresAuth: false)
        return ReadingRemoteMapper.mapItems(dtos)
    }
}
