import Foundation

@MainActor
protocol MarketplaceRepository {
    func fetchItems(typeID: Int?) async throws -> [MarketplaceItem]
    func searchItems(keyword: String, start: Int) async throws -> [MarketplaceItem]
    func fetchItemDetail(itemID: String) async throws -> MarketplaceDetail
    func fetchMySummary() async throws -> MarketplacePersonalSummary
    func publishItem(draft: MarketplaceDraft) async throws
    func updateItem(itemID: String, draft: MarketplaceUpdateDraft) async throws
    func updateItemState(itemID: String, state: MarketplaceItemState) async throws
}
