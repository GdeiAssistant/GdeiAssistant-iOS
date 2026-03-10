import Foundation

struct ScheduleQueryResultDTO: Decodable {
    let scheduleList: [ScheduleEntryDTO]
    let week: Int?
}

struct ScheduleEntryDTO: Decodable {
    let id: String?
    let scheduleLength: Int?
    let scheduleName: String?
    let scheduleType: String?
    let scheduleLesson: String?
    let scheduleTeacher: String?
    let scheduleLocation: String?
    let colorCode: String?
    let position: Int?
    let row: Int?
    let column: Int?
    let minScheduleWeek: Int?
    let maxScheduleWeek: Int?
    let scheduleWeek: String?
    let isCustom: Bool?
}
