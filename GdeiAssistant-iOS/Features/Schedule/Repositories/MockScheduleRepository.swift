import Foundation

@MainActor
final class MockScheduleRepository: ScheduleRepository {
    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockFactory.makeWeeklySchedule(weekIndex: weekIndex)
    }
}
