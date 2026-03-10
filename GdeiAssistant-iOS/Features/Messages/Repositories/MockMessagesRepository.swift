import Foundation

@MainActor
final class MockMessagesRepository: MessagesRepository {
    private var threads = MockFactory.makeInteractionThreads()

    func fetchNotifications() async throws -> [AppNotificationItem] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return MockFactory.makeNotifications()
    }

    func fetchThreads() async throws -> [InteractionThreadItem] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return threads
    }

    func markThreadRead(threadID: String) async throws {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        let current = threads[index]
        threads[index] = InteractionThreadItem(
            id: current.id,
            title: current.title,
            lastMessage: current.lastMessage,
            updatedAt: current.updatedAt,
            unreadCount: 0,
            isRead: true,
            avatarURL: current.avatarURL,
            destinationTab: current.destinationTab
        )
    }
}
