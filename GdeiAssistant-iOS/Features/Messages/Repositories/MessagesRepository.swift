import Foundation

@MainActor
protocol MessagesRepository {
    func fetchNotifications() async throws -> [AppNotificationItem]
    func fetchThreads() async throws -> [InteractionThreadItem]
    func markThreadRead(threadID: String) async throws
}

@MainActor
final class SwitchingMessagesRepository: MessagesRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any MessagesRepository
    private let mockRepository: any MessagesRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any MessagesRepository,
        mockRepository: any MessagesRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchNotifications() async throws -> [AppNotificationItem] {
        try await currentRepository.fetchNotifications()
    }

    func fetchThreads() async throws -> [InteractionThreadItem] {
        try await currentRepository.fetchThreads()
    }

    func markThreadRead(threadID: String) async throws {
        try await currentRepository.markThreadRead(threadID: threadID)
    }

    private var currentRepository: any MessagesRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
