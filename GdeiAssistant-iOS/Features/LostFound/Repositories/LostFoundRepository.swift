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

@MainActor
final class SwitchingLostFoundRepository: LostFoundRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any LostFoundRepository
    private let mockRepository: any LostFoundRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any LostFoundRepository,
        mockRepository: any LostFoundRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchItems() async throws -> [LostFoundItem] {
        try await currentRepository.fetchItems()
    }

    func fetchDetail(itemID: String) async throws -> LostFoundDetail {
        try await currentRepository.fetchDetail(itemID: itemID)
    }

    func fetchMySummary() async throws -> LostFoundPersonalSummary {
        try await currentRepository.fetchMySummary()
    }

    func publish(draft: LostFoundDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func update(itemID: String, draft: LostFoundUpdateDraft) async throws {
        try await currentRepository.update(itemID: itemID, draft: draft)
    }

    func markDidFound(itemID: String) async throws {
        try await currentRepository.markDidFound(itemID: itemID)
    }

    private var currentRepository: any LostFoundRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
