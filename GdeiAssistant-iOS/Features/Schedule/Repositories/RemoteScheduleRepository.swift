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

    func fetchCurrentWeeklySchedule() async throws -> WeeklySchedule {
        // The backend resolves the current academic week when `week` is omitted.
        let responseDTO: ScheduleQueryResultDTO = try await apiClient.get("/schedule", requiresAuth: true)
        guard let week = responseDTO.week, week > 0 else {
            throw CurrentScheduleError.missingCurrentWeek
        }
        return ScheduleRemoteMapper.mapSchedule(responseDTO, requestedWeekIndex: week)
    }
}

private enum CurrentScheduleError: Error {
    case missingCurrentWeek
}
