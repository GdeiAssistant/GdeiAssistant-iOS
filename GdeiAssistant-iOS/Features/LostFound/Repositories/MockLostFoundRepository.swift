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
            throw NetworkError.server(code: 404, message: localizedString("mock.lostFound.postNotFound"))
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
            throw NetworkError.server(code: 400, message: localizedString("mock.lostFound.uploadAtLeastOneImage"))
        }

        let itemID = "lf_\(UUID().uuidString)"
        let item = LostFoundItem(
            id: itemID,
            title: draft.title,
            type: draft.type,
            itemTypeID: draft.itemTypeID,
            summary: draft.summary,
            location: draft.location,
            createdAt: localizedString("mock.lostFound.justNow"),
            state: .active,
            previewImageURL: nil
        )
        let detail = LostFoundDetail(
            item: item,
            description: draft.description,
            contactHint: draft.contactHint,
            statusText: localizedString("mock.lostFound.searching"),
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
            throw NetworkError.server(code: 404, message: localizedString("mock.lostFound.postNotFound"))
        }
        let updatedItem = LostFoundItem(
            id: detail.item.id,
            title: draft.title,
            type: draft.type,
            itemTypeID: draft.itemTypeID,
            summary: RemoteMapperSupport.truncated(draft.description, limit: 32),
            location: draft.location,
            createdAt: localizedString("mock.lostFound.justEdited"),
            state: detail.item.state,
            previewImageURL: detail.item.previewImageURL
        )
        let contactHint = [
            draft.qq.flatMap { $0.isEmpty ? nil : String(format: localizedString("mock.lostFound.qqPrefix"), $0) },
            draft.wechat.flatMap { $0.isEmpty ? nil : String(format: localizedString("mock.lostFound.wechatPrefix"), $0) },
            draft.phone.flatMap { $0.isEmpty ? nil : String(format: localizedString("mock.lostFound.phonePrefix"), $0) }
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
            throw NetworkError.server(code: 404, message: localizedString("mock.lostFound.postNotFound"))
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
            statusText: localizedString("mock.lostFound.resolved"),
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
            title: localizedString("mock.lostFound.personalFoundTitle"),
            type: .found,
            itemTypeID: 10,
            summary: localizedString("mock.lostFound.personalFoundSummary"),
            location: localizedString("mock.lostFound.personalFoundLocation"),
            createdAt: localizedString("mock.lostFound.personalFoundTime"),
            state: .active,
            previewImageURL: "https://example.com/lostfound/u-disk-preview.png"
        )
        let resolvedItem = LostFoundItem(
            id: "lf_personal_resolved_001",
            title: localizedString("mock.lostFound.personalResolvedTitle"),
            type: .lost,
            itemTypeID: 1,
            summary: localizedString("mock.lostFound.personalResolvedSummary"),
            location: localizedString("mock.lostFound.personalResolvedLocation"),
            createdAt: localizedString("mock.lostFound.personalResolvedTime"),
            state: .resolved,
            previewImageURL: "https://example.com/lostfound/pass-preview.png"
        )

        detailsByID[foundItem.id] = LostFoundDetail(
            item: foundItem,
            description: localizedString("mock.lostFound.personalFoundDescription"),
            contactHint: localizedString("mock.lostFound.personalFoundContact"),
            statusText: localizedString("mock.lostFound.searching"),
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: ["https://example.com/lostfound/u-disk-1.png"]
        )
        detailsByID[resolvedItem.id] = LostFoundDetail(
            item: resolvedItem,
            description: localizedString("mock.lostFound.personalResolvedDescription"),
            contactHint: localizedString("mock.lostFound.personalResolvedContact"),
            statusText: localizedString("mock.lostFound.resolved"),
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: ["https://example.com/lostfound/pass-1.png"]
        )
    }
}
