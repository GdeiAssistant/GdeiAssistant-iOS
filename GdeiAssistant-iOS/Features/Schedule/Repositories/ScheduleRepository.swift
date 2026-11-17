import Foundation

@MainActor
protocol ScheduleRepository {
    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule
    func fetchCurrentWeeklySchedule() async throws -> WeeklySchedule
}
