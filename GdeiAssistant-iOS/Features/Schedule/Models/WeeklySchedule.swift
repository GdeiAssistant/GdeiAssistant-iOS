import Foundation

struct CourseItem: Codable, Identifiable, Hashable {
    let id: String
    let courseName: String
    let teacherName: String
    let location: String
    let dayOfWeek: Int
    let startSection: Int
    let endSection: Int
    let weekIndices: [Int]
}

struct CourseDaySection: Codable, Identifiable, Hashable {
    var id: String { "day_\(dayOfWeek)_\(dateText)" }

    let dayOfWeek: Int
    let dayTitle: String
    let dateText: String
    let courses: [CourseItem]
}

struct WeeklySchedule: Codable {
    let weekIndex: Int
    let termName: String
    let days: [CourseDaySection]
}

struct CustomCourseDraft: Codable, Identifiable {
    let id: String
    var courseName: String
    var teacherName: String
    var location: String
    var dayOfWeek: Int
    var startSection: Int
    var endSection: Int
}
