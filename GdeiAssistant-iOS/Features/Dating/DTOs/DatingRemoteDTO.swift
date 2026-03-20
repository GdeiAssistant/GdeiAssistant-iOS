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

struct DatingProfileDetailDTO: Decodable {
    let profile: DatingProfileDTO?
    let pictureURL: String?
    let isContactVisible: Bool?
    let isPickNotAvailable: Bool?
}

struct DatingPickDTO: Decodable {
    let pickId: Int?
    let roommateProfile: DatingProfileDTO?
    let username: String?
    let content: String?
    let state: Int?
}
