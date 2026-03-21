import Foundation

@MainActor
final class RemoteMarketplaceRepository: MarketplaceRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchItems(typeID: Int?) async throws -> [MarketplaceItem] {
        let path: String
        if let typeID {
            path = "/ershou/item/type/\(typeID)/start/0"
        } else {
            path = "/ershou/item/start/0"
        }

        let dtos: [MarketplaceItemDTO] = try await apiClient.get(path, requiresAuth: true)
        let items = MarketplaceRemoteMapper.mapItems(dtos)
        return try await enrichPreviewURLs(for: items)
    }

    func searchItems(keyword: String, start: Int) async throws -> [MarketplaceItem] {
        let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? keyword
        let dtos: [MarketplaceItemDTO] = try await apiClient.get("/ershou/keyword/\(encoded)/start/\(start)", requiresAuth: true)
        let items = MarketplaceRemoteMapper.mapItems(dtos)
        return try await enrichPreviewURLs(for: items)
    }

    func fetchItemDetail(itemID: String) async throws -> MarketplaceDetail {
        let dto: MarketplaceDetailDTO = try await apiClient.get("/ershou/item/id/\(itemID)", requiresAuth: true)
        let detail = try MarketplaceRemoteMapper.mapDetail(dto)
        guard detail.imageURLs.isEmpty else {
            return detail
        }

        let previewURL = try? await fetchPreviewURL(itemID: itemID)
        guard let previewURL else {
            return detail
        }

        return MarketplaceDetail(
            item: MarketplaceItem(
                id: detail.item.id,
                title: detail.item.title,
                price: detail.item.price,
                summary: detail.item.summary,
                sellerName: detail.item.sellerName,
                sellerAvatarURL: detail.item.sellerAvatarURL,
                postedAt: detail.item.postedAt,
                location: detail.item.location,
                state: detail.item.state,
                tags: detail.item.tags,
                previewImageURL: detail.item.previewImageURL ?? previewURL
            ),
            condition: detail.condition,
            description: detail.description,
            contactHint: detail.contactHint,
            sellerUsername: detail.sellerUsername,
            sellerNickname: detail.sellerNickname,
            sellerCollege: detail.sellerCollege,
            sellerMajor: detail.sellerMajor,
            sellerGrade: detail.sellerGrade,
            imageURLs: [previewURL]
        )
    }

    func fetchMySummary() async throws -> MarketplacePersonalSummary {
        let profile: UserProfileDTO = try await apiClient.get("/user/profile", requiresAuth: true)
        let summary: MarketplacePersonalSummaryDTO = try await apiClient.get("/ershou/profile", requiresAuth: true)
        return MarketplaceRemoteMapper.mapPersonalSummary(summary, profile: profile)
    }

    func publishItem(draft: MarketplaceDraft) async throws {
        let dto = MarketplaceRemoteMapper.mapPublishDTO(draft)
        let fields = MarketplaceRemoteMapper.mapPublishFields(dto)
        let files = MarketplaceRemoteMapper.mapPublishFiles(draft)
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/ershou/item",
            fields: fields,
            files: files,
            requiresAuth: true
        )
    }

    func updateItem(itemID: String, draft: MarketplaceUpdateDraft) async throws {
        let dto = MarketplaceRemoteMapper.mapUpdateDTO(draft)
        let fields = MarketplaceRemoteMapper.mapPublishFields(dto)
        let _: EmptyPayload = try await apiClient.postForm(
            "/ershou/item/id/\(itemID)",
            fields: fields,
            requiresAuth: true
        )
    }

    func updateItemState(itemID: String, state: MarketplaceItemState) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/ershou/item/state/id/\(itemID)",
            queryItems: [URLQueryItem(name: "state", value: String(state.rawValue))],
            requiresAuth: true
        )
    }

    private func enrichPreviewURLs(for items: [MarketplaceItem]) async throws -> [MarketplaceItem] {
        var enrichedItems = [MarketplaceItem]()
        enrichedItems.reserveCapacity(items.count)

        for item in items {
            guard item.previewImageURL == nil else {
                enrichedItems.append(item)
                continue
            }

            let previewURL = try? await fetchPreviewURL(itemID: item.id)
            enrichedItems.append(
                MarketplaceItem(
                    id: item.id,
                    title: item.title,
                    price: item.price,
                    summary: item.summary,
                    sellerName: item.sellerName,
                    sellerAvatarURL: item.sellerAvatarURL,
                    postedAt: item.postedAt,
                    location: item.location,
                    state: item.state,
                    tags: item.tags,
                    previewImageURL: previewURL ?? item.previewImageURL
                )
            )
        }

        return enrichedItems
    }

    private func fetchPreviewURL(itemID: String) async throws -> String? {
        let preview: String = try await apiClient.get("/ershou/item/id/\(itemID)/preview", requiresAuth: true)
        return RemoteMapperSupport.sanitizedText(preview)
    }
}
