import Foundation

@MainActor
final class RemoteCETRepository: CETRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCaptchaImageBase64() async throws -> String {
        let base64: String = try await apiClient.get("/cet/checkcode", requiresAuth: true)
        return base64
    }

    func queryScore(request: CETScoreQueryRequest) async throws -> CETDashboard {
        let dto = CETRemoteMapper.mapScoreQueryRequest(request)
        let scoreDTO: CETScoreDTO = try await apiClient.get(
            "/cet/query",
            queryItems: CETRemoteMapper.mapScoreQueryItems(dto),
            requiresAuth: true
        )
        return CETRemoteMapper.mapDashboard(request: request, scoreDTO: scoreDTO)
    }
}
