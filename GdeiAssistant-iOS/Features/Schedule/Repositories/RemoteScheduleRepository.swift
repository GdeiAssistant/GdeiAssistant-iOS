import Foundation

@MainActor
final class RemoteScheduleRepository: ScheduleRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule {
        let query = [URLQueryItem(name: "week", value: String(weekIndex))]
        let responseDTO: ScheduleQueryResultDTO = try await apiClient.get("/schedule", queryItems: query, requiresAuth: true)
        return ScheduleRemoteMapper.mapSchedule(responseDTO, requestedWeekIndex: weekIndex)
    }
}
