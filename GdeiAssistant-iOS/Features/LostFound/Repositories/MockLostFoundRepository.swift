import Foundation

@MainActor
final class MockLostFoundRepository: LostFoundRepository {
    private var items = MockFactory.makeLostFoundItems()
    private var detailsByID = MockFactory.makeLostFoundDetailsByID()

    init() {
        seedPersonalItemsIfNeeded()
    }

    func fetchItems() async throws -> [LostFoundItem] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return items
    }

    func fetchDetail(itemID: String) async throws -> LostFoundDetail {
        try await Task.sleep(nanoseconds: 160_000_000)

        guard let detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "帖子不存在")
        }

        return detail
    }

    func fetchMySummary() async throws -> LostFoundPersonalSummary {
        try await Task.sleep(nanoseconds: 180_000_000)
        seedPersonalItemsIfNeeded()
        let myDetails = detailsByID.values.filter { $0.ownerUsername == MockSeedData.demoProfile.username }
        let lost = myDetails
            .filter { $0.item.type == .lost && $0.item.state == .active }
            .map(\.item)
        let found = myDetails
            .filter { $0.item.type == .found && $0.item.state == .active }
            .map(\.item)
        let didFound = myDetails
            .filter { $0.item.state == .resolved }
            .map(\.item)

        return LostFoundPersonalSummary(
            avatarURL: MockSeedData.demoProfile.avatarURL,
            nickname: MockSeedData.demoProfile.nickname,
            introduction: MockSeedData.demoProfile.bio,
            lost: lost,
            found: found,
            didFound: didFound
        )
    }

    func publish(draft: LostFoundDraft) async throws {
        try await Task.sleep(nanoseconds: 220_000_000)

        guard !draft.images.isEmpty else {
            throw NetworkError.server(code: 400, message: "请至少上传一张图片")
        }

        let itemID = "lf_\(UUID().uuidString)"
        let item = LostFoundItem(
            id: itemID,
            title: draft.title,
            type: draft.type,
            itemTypeID: draft.itemTypeID,
            summary: draft.summary,
            location: draft.location,
            createdAt: "刚刚",
            state: .active,
            previewImageURL: nil
        )
        let detail = LostFoundDetail(
            item: item,
            description: draft.description,
            contactHint: draft.contactHint,
            statusText: "寻主/寻物中",
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: []
        )

        items.insert(item, at: 0)
        detailsByID[itemID] = detail
    }

    func update(itemID: String, draft: LostFoundUpdateDraft) async throws {
        guard let detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "帖子不存在")
        }
        let updatedItem = LostFoundItem(
            id: detail.item.id,
            title: draft.title,
            type: draft.type,
            itemTypeID: draft.itemTypeID,
            summary: RemoteMapperSupport.truncated(draft.description, limit: 32),
            location: draft.location,
            createdAt: "刚刚修改",
            state: detail.item.state,
            previewImageURL: detail.item.previewImageURL
        )
        let contactHint = [
            draft.qq.flatMap { $0.isEmpty ? nil : "QQ：\($0)" },
            draft.wechat.flatMap { $0.isEmpty ? nil : "微信：\($0)" },
            draft.phone.flatMap { $0.isEmpty ? nil : "手机号：\($0)" }
        ].compactMap { $0 }.joined(separator: " / ")
        detailsByID[itemID] = LostFoundDetail(
            item: updatedItem,
            description: draft.description,
            contactHint: contactHint,
            statusText: detail.statusText,
            ownerUsername: detail.ownerUsername,
            ownerNickname: detail.ownerNickname,
            ownerAvatarURL: detail.ownerAvatarURL,
            imageURLs: detail.imageURLs
        )
        syncItem(updatedItem)
    }

    func markDidFound(itemID: String) async throws {
        guard let detail = detailsByID[itemID] else {
            throw NetworkError.server(code: 404, message: "帖子不存在")
        }
        let updatedItem = LostFoundItem(
            id: detail.item.id,
            title: detail.item.title,
            type: detail.item.type,
            itemTypeID: detail.item.itemTypeID,
            summary: detail.item.summary,
            location: detail.item.location,
            createdAt: detail.item.createdAt,
            state: .resolved,
            previewImageURL: detail.item.previewImageURL
        )
        detailsByID[itemID] = LostFoundDetail(
            item: updatedItem,
            description: detail.description,
            contactHint: detail.contactHint,
            statusText: "已找回",
            ownerUsername: detail.ownerUsername,
            ownerNickname: detail.ownerNickname,
            ownerAvatarURL: detail.ownerAvatarURL,
            imageURLs: detail.imageURLs
        )
        syncItem(updatedItem)
    }

    private func syncItem(_ item: LostFoundItem) {
        items.removeAll { $0.id == item.id }
        if item.state == .active {
            items.insert(item, at: 0)
        }
    }

    private func seedPersonalItemsIfNeeded() {
        guard detailsByID["lf_personal_found_001"] == nil else { return }

        let foundItem = LostFoundItem(
            id: "lf_personal_found_001",
            title: "拾到蓝色 U 盘一个",
            type: .found,
            itemTypeID: 10,
            summary: "在教学楼 B 栋门口拾到，先登记在个人中心。",
            location: "教学楼 B 栋门口",
            createdAt: "昨天 20:10",
            state: .active,
            previewImageURL: "https://example.com/lostfound/u-disk-preview.png"
        )
        let resolvedItem = LostFoundItem(
            id: "lf_personal_resolved_001",
            title: "寻图书馆借书证",
            type: .lost,
            itemTypeID: 1,
            summary: "已经找到，保留在个人中心记录。",
            location: "图书馆服务台",
            createdAt: "前天 11:25",
            state: .resolved,
            previewImageURL: "https://example.com/lostfound/pass-preview.png"
        )

        detailsByID[foundItem.id] = LostFoundDetail(
            item: foundItem,
            description: "在教学楼 B 栋门口拾到，发布后等待失主联系。",
            contactHint: "QQ：231245678 / 微信：gdeiassistant",
            statusText: "寻主/寻物中",
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: ["https://example.com/lostfound/u-disk-1.png"]
        )
        detailsByID[resolvedItem.id] = LostFoundDetail(
            item: resolvedItem,
            description: "已经在服务台找回，保留历史记录。",
            contactHint: "QQ：231245678",
            statusText: "已找回",
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: ["https://example.com/lostfound/pass-1.png"]
        )
    }
}
