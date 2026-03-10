import Foundation

@MainActor
final class RemoteHomeRepository: HomeRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchDashboard() async throws -> HomeDashboard {
        try await apiClient.get("/home/dashboard", requiresAuth: true)
    }
}
