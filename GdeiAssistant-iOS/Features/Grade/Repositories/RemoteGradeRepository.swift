import Foundation

@MainActor
final class RemoteGradeRepository: GradeRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchGrades(yearIndex: Int?) async throws -> GradeReport {
        let requestedYear = yearIndex
        let query = requestedYear.map { [URLQueryItem(name: "year", value: String($0))] } ?? []
        let responseDTO: GradeQueryResultDTO = try await apiClient.get("/grade", queryItems: query, requiresAuth: true)
        return GradeRemoteMapper.mapReport(responseDTO, requestedYearIndex: yearIndex)
    }
}
