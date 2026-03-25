import Foundation

@MainActor
final class MockMarketplaceRepository: MarketplaceRepository {
    private var items = MockFactory.makeMarketplaceItems()
    private var detailsByID = MockFactory.makeMarketplaceDetailsByID()

    init() {
        seedPersonalItemsIfNeeded()
    }

    func fetchItems(typeID: Int?) async throws -> [MarketplaceItem] {
        try await Task.sleep(nanoseconds: 220_000_000)
        guard let typeID else {
            return items
        }
        let typeName = MarketplaceRemoteMapper.displayName(forType: typeID)
        return items.filter { $0.tags.contains(typeName) }
    }

    func searchItems(keyword: String, start: Int) async throws -> [MarketplaceItem] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let query = keyword.lowercased()
        return items.filter { $0.title.lowercased().contains(query) || $0.summary.lowercased().contains(query) }
    }

    func fetchItemDetail(itemID: String) async throws -> MarketplaceDetail {
        try await Task.sleep(nanoseconds: 160_000_000)

        guard let detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "商品不存在")
        }

        return detail
    }

    func fetchMySummary() async throws -> MarketplacePersonalSummary {
        try await Task.sleep(nanoseconds: 180_000_000)
        seedPersonalItemsIfNeeded()
        let doing = detailsByID.values
            .filter { $0.sellerUsername == MockSeedData.demoProfile.username && $0.item.state == .selling }
            .map(\.item)
            .sorted { $0.postedAt > $1.postedAt }
        let sold = detailsByID.values
            .filter { $0.sellerUsername == MockSeedData.demoProfile.username && $0.item.state == .sold }
            .map(\.item)
            .sorted { $0.postedAt > $1.postedAt }
        let off = detailsByID.values
            .filter { $0.sellerUsername == MockSeedData.demoProfile.username && $0.item.state == .offShelf }
            .map(\.item)
            .sorted { $0.postedAt > $1.postedAt }

        return MarketplacePersonalSummary(
            avatarURL: MockSeedData.demoProfile.avatarURL,
            nickname: MockSeedData.demoProfile.nickname,
            introduction: MockSeedData.demoProfile.bio,
            doing: doing,
            sold: sold,
            off: off
        )
    }

    func publishItem(draft: MarketplaceDraft) async throws {
        try await Task.sleep(nanoseconds: 220_000_000)

        guard !draft.images.isEmpty else {
            throw NetworkError.server(code: 400, message: "请至少上传一张商品图片")
        }

        let itemID = "market_\(UUID().uuidString)"
        let newItem = MarketplaceItem(
            id: itemID,
            title: draft.title,
            price: draft.price,
            summary: draft.summary,
            sellerName: MockSeedData.demoProfile.nickname,
            sellerAvatarURL: MockSeedData.demoProfile.avatarURL,
            postedAt: "刚刚",
            location: draft.location,
            state: .selling,
            tags: draft.tags,
            previewImageURL: nil
        )
        let contactHintParts = [
            draft.qq.isEmpty ? nil : "QQ：\(draft.qq)",
            draft.phone.flatMap { $0.isEmpty ? nil : "手机号：\($0)" }
        ].compactMap { $0 }
        let newDetail = MarketplaceDetail(
            item: newItem,
            condition: draft.condition,
            description: draft.description,
            contactHint: contactHintParts.joined(separator: " / "),
            sellerUsername: MockSeedData.demoProfile.username,
            sellerNickname: MockSeedData.demoProfile.nickname,
            sellerCollege: MockSeedData.demoProfile.college,
            sellerMajor: MockSeedData.demoProfile.major,
            sellerGrade: MockSeedData.demoProfile.grade,
            imageURLs: []
        )

        items.insert(newItem, at: 0)
        detailsByID[itemID] = newDetail
    }

    func updateItem(itemID: String, draft: MarketplaceUpdateDraft) async throws {
        guard let detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "商品不存在")
        }
        let contactHintParts = [
            "QQ：\(draft.qq)",
            draft.phone.flatMap { $0.isEmpty ? nil : "手机号：\($0)" }
        ].compactMap { $0 }
        let updatedItem = MarketplaceItem(
            id: detail.item.id,
            title: draft.title,
            price: draft.price,
            summary: RemoteMapperSupport.truncated(draft.description, limit: 28),
            sellerName: detail.item.sellerName,
            sellerAvatarURL: detail.item.sellerAvatarURL,
            postedAt: "刚刚修改",
            location: draft.location,
            state: detail.item.state,
            tags: [MarketplaceRemoteMapper.displayName(forType: draft.typeID)],
            previewImageURL: detail.item.previewImageURL
        )
        detailsByID[itemID] = MarketplaceDetail(
            item: updatedItem,
            condition: MarketplaceRemoteMapper.displayName(forType: draft.typeID),
            description: draft.description,
            contactHint: contactHintParts.joined(separator: " / "),
            sellerUsername: detail.sellerUsername,
            sellerNickname: detail.sellerNickname,
            sellerCollege: detail.sellerCollege,
            sellerMajor: detail.sellerMajor,
            sellerGrade: detail.sellerGrade,
            imageURLs: detail.imageURLs
        )
        syncItem(updatedItem)
    }

    func updateItemState(itemID: String, state: MarketplaceItemState) async throws {
        guard var detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "商品不存在")
        }

        let updatedItem = MarketplaceItem(
            id: detail.item.id,
            title: detail.item.title,
            price: detail.item.price,
            summary: detail.item.summary,
            sellerName: detail.item.sellerName,
            sellerAvatarURL: detail.item.sellerAvatarURL,
            postedAt: detail.item.postedAt,
            location: detail.item.location,
            state: state,
            tags: detail.item.tags,
            previewImageURL: detail.item.previewImageURL
        )
        detail = MarketplaceDetail(
            item: updatedItem,
            condition: detail.condition,
            description: detail.description,
            contactHint: detail.contactHint,
            sellerUsername: detail.sellerUsername,
            sellerNickname: detail.sellerNickname,
            sellerCollege: detail.sellerCollege,
            sellerMajor: detail.sellerMajor,
            sellerGrade: detail.sellerGrade,
            imageURLs: detail.imageURLs
        )
        detailsByID[itemID] = detail
        syncItem(updatedItem)
    }

    private func syncItem(_ item: MarketplaceItem) {
        items.removeAll { $0.id == item.id }
        if item.state == .selling {
            items.insert(item, at: 0)
        }
    }

    private func seedPersonalItemsIfNeeded() {
        guard detailsByID["market_personal_off_001"] == nil else { return }

        let offShelfItem = MarketplaceItem(
            id: "market_personal_off_001",
            title: "英语四级真题集",
            price: 16,
            summary: "课后整理的真题册，先临时下架整理中。",
            sellerName: MockSeedData.demoProfile.nickname,
            sellerAvatarURL: MockSeedData.demoProfile.avatarURL,
            postedAt: "昨天 21:10",
            location: "海珠校区教学楼",
            state: .offShelf,
            tags: ["图书教材"],
            previewImageURL: "https://example.com/market/cet-preview.png"
        )
        let soldItem = MarketplaceItem(
            id: "market_personal_sold_001",
            title: "宿舍收纳置物架",
            price: 22,
            summary: "已完成交易，保留在个人中心记录。",
            sellerName: MockSeedData.demoProfile.nickname,
            sellerAvatarURL: MockSeedData.demoProfile.avatarURL,
            postedAt: "前天 16:42",
            location: "南苑宿舍区",
            state: .sold,
            tags: ["生活娱乐"],
            previewImageURL: "https://example.com/market/rack-preview.png"
        )

        detailsByID[offShelfItem.id] = MarketplaceDetail(
            item: offShelfItem,
            condition: "图书教材",
            description: "四六级复习资料整理完成后会重新上架，当前先在个人中心保留记录。",
            contactHint: "QQ：231245678",
            sellerUsername: MockSeedData.demoProfile.username,
            sellerNickname: MockSeedData.demoProfile.nickname,
            sellerCollege: MockSeedData.demoProfile.college,
            sellerMajor: MockSeedData.demoProfile.major,
            sellerGrade: MockSeedData.demoProfile.grade,
            imageURLs: ["https://example.com/market/cet-1.png"]
        )
        detailsByID[soldItem.id] = MarketplaceDetail(
            item: soldItem,
            condition: "生活娱乐",
            description: "已与同学完成交易，这里仅保留成交记录。",
            contactHint: "QQ：231245678",
            sellerUsername: MockSeedData.demoProfile.username,
            sellerNickname: MockSeedData.demoProfile.nickname,
            sellerCollege: MockSeedData.demoProfile.college,
            sellerMajor: MockSeedData.demoProfile.major,
            sellerGrade: MockSeedData.demoProfile.grade,
            imageURLs: ["https://example.com/market/rack-1.png"]
        )
    }
}
