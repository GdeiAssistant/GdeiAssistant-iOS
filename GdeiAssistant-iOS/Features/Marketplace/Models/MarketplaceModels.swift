import Foundation

enum MarketplaceItemState: Int, Codable, Hashable {
    case unknown = -1
    case offShelf = 0
    case selling = 1
    case sold = 2
    case systemDeleted = 3

    var title: String {
        switch self {
        case .offShelf:
            return localizedString("marketplace.offShelf")
        case .selling:
            return localizedString("marketplace.stateSelling")
        case .sold:
            return localizedString("marketplace.stateSold")
        case .unknown:
            return localizedString("common.notProvided")
        case .systemDeleted:
            return localizedString("marketplace.stateSystemDeleted")
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
    /// Public social UUID when backend provides it; never invented client-side.
    let authorId: String?
    let postedAt: String
    let location: String
    let state: MarketplaceItemState
    let tags: [String]
    let previewImageURL: String?
    var typeID: Int? = nil

    func typeDisplayName(localeIdentifier: String = AppLanguage.currentIdentifier()) -> String? {
        guard let typeID else { return nil }
        return LocalizedProfileCatalog.catalog(for: localeIdentifier).defaultOptions.marketplaceItemTypes.first(where: { $0.code == typeID })?.label
    }

    func displayTags(localeIdentifier: String = AppLanguage.currentIdentifier()) -> [String] {
        typeDisplayName(localeIdentifier: localeIdentifier).map { [$0] } ?? tags
    }
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
    var ownedByCurrentUser: Bool = false

    func categoryDisplayName(localeIdentifier: String = AppLanguage.currentIdentifier()) -> String {
        item.typeDisplayName(localeIdentifier: localeIdentifier) ?? condition
    }
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
