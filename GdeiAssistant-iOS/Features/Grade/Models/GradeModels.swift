import Foundation

struct GradeItem: Codable, Identifiable, Hashable {
    let id: String
    let courseName: String
    let courseType: String
    let credit: Double
    let score: Double
    let gradePoint: Double
    let term: String
}

struct GradeSummary: Codable, Hashable {
    let gpa: Double
    let averageScore: Double
    let earnedCredits: Double
    let totalCredits: Double
}

struct GradeTermReport: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let gpa: Double
    let items: [GradeItem]
}

struct AcademicYearOption: Codable, Identifiable, Hashable {
    let id: String
    let title: String
}

struct GradeReport: Codable {
    let selectedYear: String
    let yearOptions: [AcademicYearOption]
    let summary: GradeSummary
    let terms: [GradeTermReport]
}
