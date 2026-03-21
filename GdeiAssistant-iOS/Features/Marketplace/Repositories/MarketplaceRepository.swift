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

@MainActor
final class SwitchingMarketplaceRepository: MarketplaceRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any MarketplaceRepository
    private let mockRepository: any MarketplaceRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any MarketplaceRepository,
        mockRepository: any MarketplaceRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchItems(typeID: Int?) async throws -> [MarketplaceItem] {
        try await currentRepository.fetchItems(typeID: typeID)
    }

    func searchItems(keyword: String, start: Int) async throws -> [MarketplaceItem] {
        try await currentRepository.searchItems(keyword: keyword, start: start)
    }

    func fetchItemDetail(itemID: String) async throws -> MarketplaceDetail {
        try await currentRepository.fetchItemDetail(itemID: itemID)
    }

    func fetchMySummary() async throws -> MarketplacePersonalSummary {
        try await currentRepository.fetchMySummary()
    }

    func publishItem(draft: MarketplaceDraft) async throws {
        try await currentRepository.publishItem(draft: draft)
    }

    func updateItem(itemID: String, draft: MarketplaceUpdateDraft) async throws {
        try await currentRepository.updateItem(itemID: itemID, draft: draft)
    }

    func updateItemState(itemID: String, state: MarketplaceItemState) async throws {
        try await currentRepository.updateItemState(itemID: itemID, state: state)
    }

    private var currentRepository: any MarketplaceRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
