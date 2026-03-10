import Foundation

@MainActor
final class RemoteGradeRepository: GradeRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchGrades(academicYear: String) async throws -> GradeReport {
        let requestedYear = GradeRemoteMapper.startYear(from: academicYear)
        let query = requestedYear.map { [URLQueryItem(name: "year", value: String($0))] } ?? []
        let responseDTO: GradeQueryResultDTO = try await apiClient.get("/grade", queryItems: query, requiresAuth: true)
        return GradeRemoteMapper.mapReport(responseDTO, requestedAcademicYear: academicYear)
    }
}
