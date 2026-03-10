import Foundation

struct LostFoundProfileDTO: Decodable {
    let avatarURL: String?
    let username: String?
    let nickname: String?
}

struct LostFoundItemDTO: Decodable {
    let id: Int?
    let username: String?
    let name: String?
    let description: String?
    let location: String?
    let itemType: Int?
    let lostType: Int?
    let qq: String?
    let wechat: String?
    let phone: String?
    let state: Int?
    let publishTime: RemoteFlexibleString?
    let pictureURL: [String]?
}

struct LostFoundDetailDTO: Decodable {
    let item: LostFoundItemDTO?
    let profile: LostFoundProfileDTO?
}

struct LostFoundPersonalSummaryDTO: Decodable {
    let lost: [LostFoundItemDTO]?
    let found: [LostFoundItemDTO]?
    let didfound: [LostFoundItemDTO]?
}

struct LostFoundPublishRemoteDTO: Codable {
    let name: String
    let description: String
    let location: String
    let itemType: Int
    let lostType: Int
    let qq: String?
    let wechat: String?
    let phone: String?
}
