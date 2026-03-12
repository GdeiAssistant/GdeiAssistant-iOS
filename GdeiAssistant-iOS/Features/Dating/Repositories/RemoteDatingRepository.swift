import Foundation

@MainActor
final class RemoteDatingRepository: DatingRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchReceivedPicks() async throws -> [DatingReceivedPick] {
        let dtos: [DatingPickDTO] = try await apiClient.get("/dating/pick/my/received", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapReceivedPick)
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        let dtos: [DatingPickDTO] = try await apiClient.get("/dating/pick/my/sent", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapSentPick)
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        let dtos: [DatingProfileDTO] = try await apiClient.get("/dating/profile/my", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapMyPost)
    }

    func updatePickState(pickID: String, state: DatingPickStatus) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/dating/pick/id/\(pickID)",
            queryItems: [URLQueryItem(name: "state", value: String(state.rawValue))],
            requiresAuth: true
        )
    }

    func hideProfile(profileID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/dating/profile/id/\(profileID)/state",
            queryItems: [URLQueryItem(name: "state", value: "0")],
            requiresAuth: true
        )
    }
}
