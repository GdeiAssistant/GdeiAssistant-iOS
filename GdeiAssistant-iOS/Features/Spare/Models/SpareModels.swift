import Foundation

struct SpareQuery: Equatable {
    var zone = 0
    var type = 0
    var startTime = 1
    var endTime = 2
    var minWeek = 0
    var maxWeek = 0
    var weekType = 0
    var classNumber = 1
    var minSeating: Int?
    var maxSeating: Int?
}

struct SpareRoomItem: Identifiable, Hashable {
    let id: String
    let roomNumber: String
    let roomName: String
    let roomType: String
    let zoneName: String
    let classSeating: String
    let sectionText: String
    let examSeating: String
}
