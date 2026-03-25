import Foundation
import Combine

@MainActor
final class MarketplaceViewModel: ObservableObject {
    @Published var items: [MarketplaceItem] = []
    @Published var selectedTypeID: Int?
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any MarketplaceRepository

    init(repository: any MarketplaceRepository) {
        self.repository = repository
    }

    var typeOptions: [(id: Int, title: String)] {
        MarketplaceRemoteMapper.itemTypes.enumerated().map { (id: $0.offset, title: $0.element) }
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items = try await repository.searchItems(keyword: trimmed, start: 0)
            } else {
                items = try await repository.fetchItems(typeID: selectedTypeID)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.listLoadFailed")
        }
    }

    func search() async {
        selectedTypeID = nil
        await refresh()
    }

    func clearSearch() async {
        searchQuery = ""
        await refresh()
    }

    func fetchDetail(itemID: String) async throws -> MarketplaceDetail {
        try await repository.fetchItemDetail(itemID: itemID)
    }

    func fetchMySummary() async throws -> MarketplacePersonalSummary {
        try await repository.fetchMySummary()
    }

    func publish(draft: MarketplaceDraft) async throws {
        try await repository.publishItem(draft: draft)
        await refresh()
    }

    func update(itemID: String, draft: MarketplaceUpdateDraft) async throws {
        try await repository.updateItem(itemID: itemID, draft: draft)
        await refresh()
    }

    func updateState(itemID: String, state: MarketplaceItemState) async throws {
        try await repository.updateItemState(itemID: itemID, state: state)
        await refresh()
    }
}
