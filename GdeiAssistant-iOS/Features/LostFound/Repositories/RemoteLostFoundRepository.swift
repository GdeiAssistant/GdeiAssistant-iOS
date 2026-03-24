import Foundation

@MainActor
final class RemoteLostFoundRepository: LostFoundRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchItems() async throws -> [LostFoundItem] {
        async let lostTask: [LostFoundItemDTO] = apiClient.get("/lostandfound/lostitem/start/0", requiresAuth: true)
        async let foundTask: [LostFoundItemDTO] = apiClient.get("/lostandfound/founditem/start/0", requiresAuth: true)
        let lostItems = try await lostTask
        let foundItems = try await foundTask
        return LostFoundRemoteMapper.mapItems(lostItems: lostItems, foundItems: foundItems)
    }

    func fetchDetail(itemID: String) async throws -> LostFoundDetail {
        let dto: LostFoundDetailDTO = try await apiClient.get("/lostandfound/item/id/\(itemID)", requiresAuth: true)
        let detail = try LostFoundRemoteMapper.mapDetail(dto)
        guard detail.imageURLs.isEmpty else {
            return detail
        }

        let previewURL = try? await fetchPreviewURL(itemID: itemID)
        guard let previewURL else {
            return detail
        }

        return LostFoundDetail(
            item: LostFoundItem(
                id: detail.item.id,
                title: detail.item.title,
                type: detail.item.type,
                itemTypeID: detail.item.itemTypeID,
                summary: detail.item.summary,
                location: detail.item.location,
                createdAt: detail.item.createdAt,
                state: detail.item.state,
                previewImageURL: detail.item.previewImageURL ?? previewURL
            ),
            description: detail.description,
            contactHint: detail.contactHint,
            statusText: detail.statusText,
            ownerUsername: detail.ownerUsername,
            ownerNickname: detail.ownerNickname,
            ownerAvatarURL: detail.ownerAvatarURL,
            imageURLs: [previewURL]
        )
    }

    func fetchMySummary() async throws -> LostFoundPersonalSummary {
        let profile: UserProfileDTO = try await apiClient.get("/user/profile", requiresAuth: true)
        let summary: LostFoundPersonalSummaryDTO = try await apiClient.get("/lostandfound/profile", requiresAuth: true)
        return LostFoundRemoteMapper.mapPersonalSummary(summary, profile: profile)
    }

    func publish(draft: LostFoundDraft) async throws {
        let dto = LostFoundRemoteMapper.mapPublishDTO(draft)
        let fields = LostFoundRemoteMapper.mapPublishFields(dto)
        let files = LostFoundRemoteMapper.mapPublishFiles(draft)
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/lostandfound/item",
            fields: fields,
            files: files,
            requiresAuth: true
        )
    }

    func update(itemID: String, draft: LostFoundUpdateDraft) async throws {
        let dto = LostFoundRemoteMapper.mapUpdateDTO(draft)
        let fields = LostFoundRemoteMapper.mapPublishFields(dto)
        let _: EmptyPayload = try await apiClient.postForm(
            "/lostandfound/item/id/\(itemID)",
            fields: fields,
            requiresAuth: true
        )
    }

    func markDidFound(itemID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/lostandfound/item/id/\(itemID)/didfound",
            requiresAuth: true
        )
    }

    private func fetchPreviewURL(itemID: String) async throws -> String? {
        let preview: String = try await apiClient.get("/lostandfound/item/id/\(itemID)/preview", requiresAuth: true)
        return RemoteMapperSupport.sanitizedText(preview)
    }
}
