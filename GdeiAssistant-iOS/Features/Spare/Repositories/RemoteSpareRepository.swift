import Foundation

@MainActor
final class RemoteSpareRepository: SpareRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem] {
        let dto = SpareRemoteMapper.mapQuery(query)
        let response: [SpareRoomRemoteDTO] = try await apiClient.post("/spare/query", body: dto, requiresAuth: true)
        return SpareRemoteMapper.mapItems(response)
    }
}
