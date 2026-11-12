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

extension MarketplaceItem {
    /// The single place that enumerates every stored field when copying an item.
    /// `nil` means "keep the current value"; optional fields can only be replaced with a
    /// non-nil value here. Reconstructing the struct by hand silently dropped `typeID`,
    /// so an edited item kept showing its old category.
    func with(
        title: String? = nil,
        price: Double? = nil,
        summary: String? = nil,
        sellerName: String? = nil,
        sellerAvatarURL: String? = nil,
        authorId: String? = nil,
        postedAt: String? = nil,
        location: String? = nil,
        state: MarketplaceItemState? = nil,
        tags: [String]? = nil,
        previewImageURL: String? = nil,
        typeID: Int? = nil
    ) -> MarketplaceItem {
        MarketplaceItem(
            id: id,
            title: title ?? self.title,
            price: price ?? self.price,
            summary: summary ?? self.summary,
            sellerName: sellerName ?? self.sellerName,
            sellerAvatarURL: sellerAvatarURL ?? self.sellerAvatarURL,
            authorId: authorId ?? self.authorId,
            postedAt: postedAt ?? self.postedAt,
            location: location ?? self.location,
            state: state ?? self.state,
            tags: tags ?? self.tags,
            previewImageURL: previewImageURL ?? self.previewImageURL,
            typeID: typeID ?? self.typeID
        )
    }
}

extension MarketplaceDetail {
    /// The single place that enumerates every stored field when copying a detail.
    /// `nil` means "keep the current value". Reconstructing by hand silently reset
    /// `ownedByCurrentUser`, which controls whether the owner sees the edit actions.
    func with(
        item: MarketplaceItem? = nil,
        condition: String? = nil,
        description: String? = nil,
        contactHint: String? = nil,
        imageURLs: [String]? = nil,
        ownedByCurrentUser: Bool? = nil
    ) -> MarketplaceDetail {
        MarketplaceDetail(
            item: item ?? self.item,
            condition: condition ?? self.condition,
            description: description ?? self.description,
            contactHint: contactHint ?? self.contactHint,
            sellerUsername: sellerUsername,
            sellerNickname: sellerNickname,
            sellerCollege: sellerCollege,
            sellerMajor: sellerMajor,
            sellerGrade: sellerGrade,
            imageURLs: imageURLs ?? self.imageURLs,
            ownedByCurrentUser: ownedByCurrentUser ?? self.ownedByCurrentUser
        )
    }
}
