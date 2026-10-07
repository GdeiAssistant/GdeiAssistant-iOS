import Foundation
import Combine

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var selectedWeekIndex: Int
    @Published var schedule: WeeklySchedule?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var loadGeneration = 0
    private let repository: any ScheduleRepository

    init(repository: any ScheduleRepository, initialWeekIndex: Int = 6) {
        self.repository = repository
        self.selectedWeekIndex = initialWeekIndex
    }

    var todayCourses: [CourseItem] {
        guard let schedule else { return [] }
        let weekday = Calendar.current.component(.weekday, from: Date())
        let normalizedWeekday = ((weekday + 5) % 7) + 1
        return schedule.days.first(where: { $0.dayOfWeek == normalizedWeekday })?.courses ?? []
    }

    func loadIfNeeded() async {
        guard schedule == nil else { return }
        await loadSchedule(weekIndex: selectedWeekIndex)
    }

    func loadSchedule(weekIndex: Int? = nil) async {
        loadGeneration += 1
        let generation = loadGeneration
        let targetWeek = weekIndex ?? selectedWeekIndex
        selectedWeekIndex = max(1, targetWeek)
        isLoading = true
        errorMessage = nil

        defer { if generation == loadGeneration { isLoading = false } }

        do {
            let result = try await repository.fetchWeeklySchedule(weekIndex: selectedWeekIndex)
            guard generation == loadGeneration, !Task.isCancelled else { return }
            schedule = result
        } catch {
            guard generation == loadGeneration, !Task.isCancelled else { return }
            schedule = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("schedule.loadFailed")
        }
    }

    func previousWeek() async {
        await loadSchedule(weekIndex: max(1, selectedWeekIndex - 1))
    }

    func nextWeek() async {
        await loadSchedule(weekIndex: selectedWeekIndex + 1)
    }
}
