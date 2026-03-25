import Foundation

@MainActor
final class RemoteGraduateExamRepository: GraduateExamRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func queryScore(_ query: GraduateExamQuery) async throws -> GraduateExamScore {
        let dto = GraduateExamRemoteMapper.mapQuery(query)
        let response: GraduateExamScoreRemoteDTO = try await apiClient.post("/graduate-exam/query", body: dto, requiresAuth: false)
        return GraduateExamRemoteMapper.mapScore(response)
    }
}
