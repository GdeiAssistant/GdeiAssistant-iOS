import Foundation

@MainActor
protocol ScheduleRepository {
    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule
}

@MainActor
final class SwitchingScheduleRepository: ScheduleRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any ScheduleRepository
    private let mockRepository: any ScheduleRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any ScheduleRepository,
        mockRepository: any ScheduleRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchWeeklySchedule(weekIndex: Int) async throws -> WeeklySchedule {
        try await currentRepository.fetchWeeklySchedule(weekIndex: weekIndex)
    }

    private var currentRepository: any ScheduleRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
