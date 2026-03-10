import Foundation

@MainActor
final class RemoteEvaluateRepository: EvaluateRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func submit(_ submission: EvaluateSubmission) async throws {
        let dto = EvaluateRemoteMapper.mapSubmitDTO(submission)
        let _: EmptyPayload = try await apiClient.post("/evaluate/submit", body: dto, requiresAuth: true)
    }
}
