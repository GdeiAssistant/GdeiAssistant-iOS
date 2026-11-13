import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var currentSchedule: WeeklySchedule?
    @Published private(set) var isScheduleLoading = false
    @Published private(set) var scheduleLoadFailed = false

    private let scheduleRepository: any ScheduleRepository
    private let now: () -> Date
    private var scheduleLoadGeneration = 0
    private var loadedScheduleDay: Date?

    init(scheduleRepository: any ScheduleRepository, now: @escaping () -> Date = Date.init) {
        self.scheduleRepository = scheduleRepository
        self.now = now
    }

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func loadIfNeeded() async {
        if loadedScheduleDay != Self.campusCalendar.startOfDay(for: now()) {
            await loadTodaySchedule()
        }
    }

    var todayCourses: [CourseItem] {
        guard let currentSchedule else { return [] }
        return Self.todayCourses(in: currentSchedule, on: now())
    }

    var todayDate: Date { now() }

    static func campusDateDescription(on date: Date, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(
            locale: locale,
            calendar: campusCalendar,
            timeZone: campusCalendar.timeZone
        ).weekday(.wide).month(.wide).day())
    }

    static var campusCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    static func todayCourses(in schedule: WeeklySchedule, on date: Date) -> [CourseItem] {
        let weekday = campusCalendar.component(.weekday, from: date)
        let dayOfWeek = ((weekday + 5) % 7) + 1
        return schedule.days.flatMap(\.courses)
            .filter {
                $0.dayOfWeek == dayOfWeek &&
                    ($0.weekIndices.isEmpty || $0.weekIndices.contains(schedule.weekIndex))
            }
            .sorted {
                if $0.startSection != $1.startSection { return $0.startSection < $1.startSection }
                if $0.endSection != $1.endSection { return $0.endSection < $1.endSection }
                if $0.courseName != $1.courseName { return $0.courseName < $1.courseName }
                return $0.id < $1.id
            }
    }

    func loadTodaySchedule() async {
        scheduleLoadGeneration += 1
        let generation = scheduleLoadGeneration
        let requestedDay = Self.campusCalendar.startOfDay(for: now())
        isScheduleLoading = true
        scheduleLoadFailed = false
        currentSchedule = nil
        loadedScheduleDay = nil
        defer { if generation == scheduleLoadGeneration { isScheduleLoading = false } }

        do {
            let result = try await scheduleRepository.fetchCurrentWeeklySchedule()
            guard generation == scheduleLoadGeneration, !Task.isCancelled else { return }
            guard requestedDay == Self.campusCalendar.startOfDay(for: now()) else {
                // Do not show yesterday's response or turn unknown data into "no courses".
                await loadTodaySchedule()
                return
            }
            currentSchedule = result
            loadedScheduleDay = requestedDay
        } catch {
            guard generation == scheduleLoadGeneration, !Task.isCancelled else { return }
            loadedScheduleDay = nil
            scheduleLoadFailed = true
        }
    }

    func refresh() async {
        await loadTodaySchedule()
    }
}
