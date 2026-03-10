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

        let groupedCourses = Dictionary(grouping: courseItems, by: \.dayOfWeek)
        let daySymbols = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

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
            weekIndex: resolvedWeekIndex,
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
            courseName: nonEmpty(dto.scheduleName, fallback: "未命名课程"),
            teacherName: nonEmpty(dto.scheduleTeacher, fallback: "待定教师"),
            location: nonEmpty(dto.scheduleLocation, fallback: "待定地点"),
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
        let termText = (2 ... 7).contains(currentMonth) ? "第二学期" : "第一学期"
        return "\(startYear)-\(startYear + 1) 学年\(termText)"
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
