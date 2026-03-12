import Foundation

@MainActor
final class RemoteReadingRepository: ReadingRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchReadings(start: Int, size: Int) async throws -> [ReadingItem] {
        let information: InformationRemoteDTO = try await apiClient.get(
            "/information/list",
            requiresAuth: true
        )

        let mappedItems = ReadingRemoteMapper.mapItems(information.topics ?? [])
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < mappedItems.count else { return [] }
        return Array(mappedItems.dropFirst(safeStart).prefix(safeSize))
    }
}
