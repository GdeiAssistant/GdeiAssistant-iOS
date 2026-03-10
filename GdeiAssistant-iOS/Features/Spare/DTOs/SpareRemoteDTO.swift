import Foundation

struct SpareQueryRemoteDTO: Encodable {
    let zone: Int
    let type: Int
    let minSeating: Int?
    let maxSeating: Int?
    let startTime: Int
    let endTime: Int
    let minWeek: Int
    let maxWeek: Int
    let weekType: Int
    let classNumber: Int
}

struct SpareRoomRemoteDTO: Decodable {
    let number: String?
    let name: String?
    let type: String?
    let zone: String?
    let classSeating: String?
    let section: String?
    let examSeating: String?
}
