import Foundation

enum ScheduleRemoteMapper {
    static func mapSchedule(
        _ dto: ScheduleQueryResultDTO,
        requestedWeekIndex: Int
    ) -> WeeklySchedule {
        let resolvedWeekIndex = max(1, dto.week ?? requestedWeekIndex)
        let courseItems = dto.scheduleList.map { entry in
            mapCourse(entry, fallbackWeekIndex: resolvedWeekIndex)
        }

        return makeSchedule(courseItems: courseItems, weekIndex: resolvedWeekIndex)
    }

    static func mapCurrentSchedule(_ dto: ScheduleQueryResultDTO) throws -> WeeklySchedule {
        guard let week = dto.week, (1...20).contains(week) else {
            throw CurrentScheduleMappingError.invalidCurrentWeek
        }
        let courseItems = try dto.scheduleList.map { entry in
            if let position = entry.position, !(0...69).contains(position) {
                throw CurrentScheduleMappingError.incompleteCourse
            }
            let column = entry.column ?? entry.position.map { $0 % 7 }
            let row = entry.row ?? entry.position.map { $0 / 7 }
            let name = entry.scheduleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let column, (0...6).contains(column),
                  let row, (0...9).contains(row),
                  let length = entry.scheduleLength, (1...5).contains(length), row + length <= 10,
                  let minWeek = entry.minScheduleWeek, let maxWeek = entry.maxScheduleWeek,
                  minWeek >= 1, maxWeek <= 20, minWeek <= maxWeek, !name.isEmpty else {
                throw CurrentScheduleMappingError.incompleteCourse
            }
            // Backend row is zero-based; length is the real grid span in sections.
            // Numeric week bounds also cover its "第1周至第16周" display label.
            return CourseItem(
                id: entry.id ?? "\(column)-\(row)-\(name)",
                courseName: name,
                teacherName: entry.scheduleTeacher?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                location: entry.scheduleLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                dayOfWeek: column + 1,
                startSection: row + 1,
                endSection: row + length,
                weekIndices: Array(minWeek...maxWeek)
            )
        }
        return makeSchedule(courseItems: courseItems, weekIndex: week)
    }

    private static func makeSchedule(courseItems: [CourseItem], weekIndex: Int) -> WeeklySchedule {
        let groupedCourses = Dictionary(grouping: courseItems, by: \.dayOfWeek)
        let daySymbols = [
            localizedString("schedule.weekday.mon"),
            localizedString("schedule.weekday.tue"),
            localizedString("schedule.weekday.wed"),
            localizedString("schedule.weekday.thu"),
            localizedString("schedule.weekday.fri"),
            localizedString("schedule.weekday.sat"),
            localizedString("schedule.weekday.sun")
        ]

        let days = daySymbols.enumerated().map { index, title in
            let dayOfWeek = index + 1
            let sortedCourses = (groupedCourses[dayOfWeek] ?? []).sorted {
                if $0.startSection == $1.startSection {
                    return $0.courseName < $1.courseName
                }
                return $0.startSection < $1.startSection
            }

            return CourseDaySection(
                dayOfWeek: dayOfWeek,
                dayTitle: title,
                dateText: "",
                courses: sortedCourses
            )
        }

        return WeeklySchedule(
            weekIndex: weekIndex,
            termName: currentAcademicTermText(),
            days: days
        )
    }

    private static func mapCourse(_ dto: ScheduleEntryDTO, fallbackWeekIndex: Int) -> CourseItem {
        let dayOfWeek = resolveDayOfWeek(entry: dto)
        let startSection = resolveStartSection(entry: dto)
        let scheduleLength = max(1, dto.scheduleLength ?? 1)
        let endSection = startSection + scheduleLength - 1
        let weekIndices = resolveWeekIndices(entry: dto, fallbackWeekIndex: fallbackWeekIndex)

        return CourseItem(
            id: dto.id ?? UUID().uuidString,
            courseName: nonEmpty(dto.scheduleName, fallback: localizedString("schedule.mapper.unnamedCourse")),
            teacherName: nonEmpty(dto.scheduleTeacher, fallback: localizedString("schedule.mapper.pendingTeacher")),
            location: nonEmpty(dto.scheduleLocation, fallback: localizedString("schedule.mapper.pendingLocation")),
            dayOfWeek: dayOfWeek,
            startSection: startSection,
            endSection: endSection,
            weekIndices: weekIndices
        )
    }

    private static func resolveDayOfWeek(entry: ScheduleEntryDTO) -> Int {
        if let column = entry.column {
            return min(max(column + 1, 1), 7)
        }
        if let position = entry.position {
            return min(max((position % 7) + 1, 1), 7)
        }
        return 1
    }

    private static func resolveStartSection(entry: ScheduleEntryDTO) -> Int {
        if let row = entry.row {
            return max(1, row + 1)
        }

        if let lesson = entry.scheduleLesson, let parsedValue = firstInteger(in: lesson) {
            return max(1, parsedValue)
        }

        if let position = entry.position {
            return max(1, (position / 7) + 1)
        }

        return 1
    }

    private static func resolveWeekIndices(entry: ScheduleEntryDTO, fallbackWeekIndex: Int) -> [Int] {
        if let rawWeekText = entry.scheduleWeek?.trimmingCharacters(in: .whitespacesAndNewlines), !rawWeekText.isEmpty {
            let separators = CharacterSet(charactersIn: ",，、;；")
            let fragments = rawWeekText.components(separatedBy: separators).filter { !$0.isEmpty }
            var weekSet = Set<Int>()

            for fragment in fragments {
                let values = integers(in: fragment)
                if fragment.contains("-"), values.count >= 2 {
                    let lowerBound = min(values[0], values[1])
                    let upperBound = max(values[0], values[1])
                    weekSet.formUnion(lowerBound ... upperBound)
                } else if let firstValue = values.first {
                    weekSet.insert(firstValue)
                }
            }

            let sortedWeeks = weekSet.sorted()
            if !sortedWeeks.isEmpty {
                return sortedWeeks
            }
        }

        if let minWeek = entry.minScheduleWeek, let maxWeek = entry.maxScheduleWeek, minWeek <= maxWeek {
            return Array(minWeek ... maxWeek)
        }

        return [fallbackWeekIndex]
    }

    private static func currentAcademicTermText() -> String {
        let currentDate = Date()
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let startYear = currentMonth >= 8 ? currentYear : currentYear - 1
        let termText = (2 ... 7).contains(currentMonth)
            ? localizedString("schedule.mapper.secondTerm")
            : localizedString("schedule.mapper.firstTerm")
        return String(format: localizedString("schedule.mapper.academicYear"), startYear, startYear + 1, termText)
    }

    private static func firstInteger(in text: String) -> Int? {
        integers(in: text).first
    }

    private static func integers(in text: String) -> [Int] {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let valueRange = Range(match.range, in: text) else {
                return nil
            }
            return Int(text[valueRange])
        }
    }

    private static func nonEmpty(_ value: String?, fallback: String) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private enum CurrentScheduleMappingError: Error {
    case invalidCurrentWeek
    case incompleteCourse
}
