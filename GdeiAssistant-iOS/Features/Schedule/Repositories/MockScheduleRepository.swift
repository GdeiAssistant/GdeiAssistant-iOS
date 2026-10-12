import Foundation

@MainActor
final class MockScheduleRepository: ScheduleRepository {
    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockFactory.makeWeeklySchedule(weekIndex: weekIndex)
    }

    func fetchCurrentWeeklySchedule() async throws -> WeeklySchedule {
        // The existing synthetic dataset uses week 6; production resolves it on the server.
        try await fetchWeeklySchedule(weekIndex: 6)
    }
}
