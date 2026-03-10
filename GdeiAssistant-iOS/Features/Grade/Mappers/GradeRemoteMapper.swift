import Foundation

enum GradeRemoteMapper {
    static func mapReport(
        _ dto: GradeQueryResultDTO,
        requestedAcademicYear: String
    ) -> GradeReport {
        let selectedStartYear = dto.year ?? startYear(from: requestedAcademicYear) ?? currentAcademicStartYear()
        let selectedYear = academicYearText(startYear: selectedStartYear)

        let firstTermItems = (dto.firstTermGradeList ?? []).map {
            mapGradeItem($0, fallbackAcademicYear: selectedYear, fallbackTerm: "1")
        }
        let secondTermItems = (dto.secondTermGradeList ?? []).map {
            mapGradeItem($0, fallbackAcademicYear: selectedYear, fallbackTerm: "2")
        }
        let allItems = (firstTermItems + secondTermItems).sorted { lhs, rhs in
            if lhs.term == rhs.term {
                return lhs.courseName < rhs.courseName
            }
            return lhs.term < rhs.term
        }

        let terms = [
            GradeTermReport(
                id: "1",
                title: "第一学期",
                gpa: dto.firstTermGPA ?? calculateTermGPA(firstTermItems),
                items: firstTermItems
            ),
            GradeTermReport(
                id: "2",
                title: "第二学期",
                gpa: dto.secondTermGPA ?? calculateTermGPA(secondTermItems),
                items: secondTermItems
            )
        ]

        return GradeReport(
            selectedYear: selectedYear,
            yearOptions: buildYearOptions(selectedStartYear: selectedStartYear),
            summary: buildSummary(dto: dto, items: allItems),
            terms: terms
        )
    }

    static func startYear(from academicYear: String) -> Int? {
        let pattern = #"\d{4}"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: academicYear,
                range: NSRange(academicYear.startIndex..<academicYear.endIndex, in: academicYear)
            ),
            let range = Range(match.range, in: academicYear)
        else {
            return nil
        }

        return Int(academicYear[range])
    }

    private static func mapGradeItem(
        _ dto: GradeEntryDTO,
        fallbackAcademicYear: String,
        fallbackTerm: String
    ) -> GradeItem {
        let gradeYear = nonEmpty(dto.gradeYear, fallback: fallbackAcademicYear)
        let termValue = nonEmpty(dto.gradeTerm, fallback: fallbackTerm)

        return GradeItem(
            id: dto.gradeId ?? "\(gradeYear)-\(termValue)-\(nonEmpty(dto.gradeName, fallback: "unknown"))",
            courseName: nonEmpty(dto.gradeName, fallback: "未命名课程"),
            courseType: nonEmpty(dto.gradeType, fallback: "未分类"),
            credit: numericValue(from: dto.gradeCredit),
            score: numericValue(from: dto.gradeScore),
            gradePoint: numericValue(from: dto.gradeGpa),
            term: "\(gradeYear)-\(termValue)"
        )
    }

    private static func buildSummary(dto: GradeQueryResultDTO, items: [GradeItem]) -> GradeSummary {
        let totalCredits = items.reduce(0) { $0 + $1.credit }
        let earnedCredits = items.reduce(0) { partialResult, item in
            partialResult + (item.score >= 60 ? item.credit : 0)
        }

        let numericScores = items.map(\.score).filter { $0 > 0 }
        let averageScore = numericScores.isEmpty ? 0 : numericScores.reduce(0, +) / Double(numericScores.count)

        let gpaCandidates = [dto.firstTermGPA, dto.secondTermGPA].compactMap { $0 }
        let calculatedGPA: Double
        if !gpaCandidates.isEmpty {
            calculatedGPA = gpaCandidates.reduce(0, +) / Double(gpaCandidates.count)
        } else {
            let weightedPoints = items.reduce(0) { $0 + ($1.gradePoint * $1.credit) }
            calculatedGPA = totalCredits > 0 ? weightedPoints / totalCredits : 0
        }

        return GradeSummary(
            gpa: calculatedGPA,
            averageScore: averageScore,
            earnedCredits: earnedCredits,
            totalCredits: totalCredits
        )
    }

    private static func calculateTermGPA(_ items: [GradeItem]) -> Double {
        let totalCredits = items.reduce(0) { $0 + $1.credit }
        let weightedPoints = items.reduce(0) { $0 + ($1.gradePoint * $1.credit) }
        return totalCredits > 0 ? weightedPoints / totalCredits : 0
    }

    private static func buildYearOptions(selectedStartYear: Int) -> [AcademicYearOption] {
        (0..<4).map { offset in
            let startYear = selectedStartYear - offset
            let title = academicYearText(startYear: startYear)
            return AcademicYearOption(id: title, title: title)
        }
    }

    private static func academicYearText(startYear: Int) -> String {
        "\(startYear)-\(startYear + 1)"
    }

    private static func currentAcademicStartYear() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        return currentMonth >= 8 ? currentYear : currentYear - 1
    }

    private static func numericValue(from text: String?) -> Double {
        let rawText = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawText.isEmpty else { return 0 }

        let pattern = #"\d+(\.\d+)?"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: rawText,
                range: NSRange(rawText.startIndex..<rawText.endIndex, in: rawText)
            ),
            let range = Range(match.range, in: rawText)
        else {
            return 0
        }

        return Double(rawText[range]) ?? 0
    }

    private static func nonEmpty(_ value: String?, fallback: String) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }
}
