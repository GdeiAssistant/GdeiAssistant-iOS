import Foundation
import Combine

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var notifications: [AppNotificationItem] = []
    @Published var threads: [InteractionThreadItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    var campusInfoItems: [AppNotificationItem] {
        notifications.filter { $0.category == .service }
    }

    var systemNoticeItems: [AppNotificationItem] {
        notifications.filter { $0.category == .system }
    }

    var interactionNoticeItems: [AppNotificationItem] {
        notifications.filter { $0.category == .interaction || $0.category == .comment || $0.category == .like }
    }

    func loadIfNeeded() async {
        guard notifications.isEmpty && threads.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let notificationsTask = repository.fetchNotifications()
            async let threadsTask = repository.fetchThreads()
            notifications = try await notificationsTask
            threads = try await threadsTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载资讯信息失败"
        }
    }

    func markThreadRead(threadID: String) async {
        guard let index = threads.firstIndex(where: { $0.id == threadID }), !threads[index].isRead else { return }

        do {
            try await repository.markThreadRead(threadID: threadID)
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
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "更新消息状态失败"
        }
    }
}
