import Foundation
import Combine

@MainActor
final class LostFoundViewModel: ObservableObject {
    @Published var items: [LostFoundItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any LostFoundRepository

    init(repository: any LostFoundRepository) {
        self.repository = repository
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
            items = try await repository.fetchItems()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "失物招领加载失败"
        }
    }

    func fetchDetail(itemID: String) async throws -> LostFoundDetail {
        try await repository.fetchDetail(itemID: itemID)
    }

    func fetchMySummary() async throws -> LostFoundPersonalSummary {
        try await repository.fetchMySummary()
    }

    func publish(draft: LostFoundDraft) async throws {
        try await repository.publish(draft: draft)
        await refresh()
    }

    func update(itemID: String, draft: LostFoundUpdateDraft) async throws {
        try await repository.update(itemID: itemID, draft: draft)
        await refresh()
    }

    func markDidFound(itemID: String) async throws {
        try await repository.markDidFound(itemID: itemID)
        await refresh()
    }
}
