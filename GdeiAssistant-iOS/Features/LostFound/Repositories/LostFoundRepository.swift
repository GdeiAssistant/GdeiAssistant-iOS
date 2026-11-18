import Foundation

@MainActor
protocol LostFoundRepository {
    func fetchItems() async throws -> [LostFoundItem]
    func fetchDetail(itemID: String) async throws -> LostFoundDetail
    func fetchMySummary() async throws -> LostFoundPersonalSummary
    func publish(draft: LostFoundDraft) async throws
    func update(itemID: String, draft: LostFoundUpdateDraft) async throws
    func markDidFound(itemID: String) async throws
}
