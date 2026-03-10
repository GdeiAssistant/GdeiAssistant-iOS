import Foundation

enum MarketplaceItemState: Int, Codable, Hashable {
    case offShelf = 0
    case selling = 1
    case sold = 2
    case systemDeleted = 3

    var title: String {
        switch self {
        case .offShelf:
            return "已下架"
        case .selling:
            return "待出售"
        case .sold:
            return "已出售"
        case .systemDeleted:
            return "系统删除"
        }
    }
}

struct MarketplaceItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let price: Double
    let summary: String
    let sellerName: String
    let sellerAvatarURL: String?
    let postedAt: String
    let location: String
    let state: MarketplaceItemState
    let tags: [String]
    let previewImageURL: String?
}

struct MarketplaceDetail: Codable, Identifiable, Hashable {
    var id: String { item.id }

    let item: MarketplaceItem
    let condition: String
    let description: String
    let contactHint: String
    let sellerUsername: String?
    let sellerNickname: String?
    let sellerCollege: String?
    let sellerMajor: String?
    let sellerGrade: String?
    let imageURLs: [String]
}

struct MarketplacePersonalSummary: Codable, Hashable {
    let avatarURL: String?
    let nickname: String
    let introduction: String
    let doing: [MarketplaceItem]
    let sold: [MarketplaceItem]
    let off: [MarketplaceItem]
}

struct MarketplaceDraft: Codable {
    let title: String
    let price: Double
    let summary: String
    let condition: String
    let description: String
    let location: String
    let tags: [String]
    let typeID: Int
    let qq: String
    let phone: String?
    let images: [UploadImageAsset]
}

struct MarketplaceUpdateDraft: Codable {
    let title: String
    let price: Double
    let description: String
    let location: String
    let typeID: Int
    let qq: String
    let phone: String?
}
