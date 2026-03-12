import Foundation

struct DatingProfileDTO: Decodable {
    let profileId: Int?
    let username: String?
    let nickname: String?
    let grade: Int?
    let faculty: String?
    let hometown: String?
    let content: String?
    let qq: String?
    let wechat: String?
    let area: Int?
    let state: Int?
    let pictureURL: String?
}

struct DatingPickDTO: Decodable {
    let pickId: Int?
    let roommateProfile: DatingProfileDTO?
    let username: String?
    let content: String?
    let state: Int?
}
