import Foundation
import Combine

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var selectedWeekIndex: Int
    @Published var schedule: WeeklySchedule?
    @Published var isLoading = false
    @Published var errorMessage: String?

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
        let targetWeek = weekIndex ?? selectedWeekIndex
        selectedWeekIndex = max(1, targetWeek)
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            schedule = try await repository.fetchWeeklySchedule(weekIndex: selectedWeekIndex)
        } catch {
            schedule = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "课表加载失败"
        }
    }

    func previousWeek() async {
        await loadSchedule(weekIndex: max(1, selectedWeekIndex - 1))
    }

    func nextWeek() async {
        await loadSchedule(weekIndex: selectedWeekIndex + 1)
    }
}
