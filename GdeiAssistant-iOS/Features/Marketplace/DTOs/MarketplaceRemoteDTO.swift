import Foundation

struct MarketplaceProfileDTO: Decodable {
    let avatarURL: String?
    let username: String?
    let nickname: String?
    let faculty: Int?
    let enrollment: Int?
    let major: String?
}

struct MarketplaceItemDTO: Decodable {
    let id: Int?
    let username: String?
    let name: String?
    let description: String?
    let price: RemoteFlexibleString?
    let location: String?
    let type: Int?
    let qq: String?
    let phone: String?
    let state: Int?
    let publishTime: RemoteFlexibleString?
    let pictureURL: [String]?
}

struct MarketplaceDetailDTO: Decodable {
    let profile: MarketplaceProfileDTO?
    let secondhandItem: MarketplaceItemDTO?
}

struct MarketplacePersonalSummaryDTO: Decodable {
    let doing: [MarketplaceItemDTO]?
    let sold: [MarketplaceItemDTO]?
    let off: [MarketplaceItemDTO]?
}

struct MarketplacePublishRemoteDTO: Codable {
    let name: String
    let description: String
    let price: Double
    let location: String
    let type: Int
    let qq: String?
    let phone: String?
}

typealias MarketplaceUpdateRemoteDTO = MarketplacePublishRemoteDTO
