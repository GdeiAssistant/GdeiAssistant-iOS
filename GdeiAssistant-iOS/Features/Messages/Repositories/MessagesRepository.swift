import Foundation

struct NotificationPage: Equatable {
    let items: [AppNotificationItem]
    let fetchedCount: Int
}

@MainActor
protocol MessagesRepository {
    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchAnnouncementBatch(start: Int, size: Int) async throws -> NotificationPage
    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchInteractionBatch(start: Int, size: Int) async throws -> NotificationPage
    func fetchInteractionUnreadCount() async throws -> Int
    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem
    func fetchFestival() async throws -> Festival?
    func markNotificationRead(notificationID: String) async throws
    func markAllNotificationsRead() async throws
}

extension MessagesRepository {
    func fetchAnnouncementBatch(start: Int, size: Int) async throws -> NotificationPage {
        let items = try await fetchAnnouncementPage(start: start, size: size)
        return NotificationPage(items: items, fetchedCount: items.count)
    }

    func fetchInteractionBatch(start: Int, size: Int) async throws -> NotificationPage {
        let items = try await fetchInteractionNotifications(start: start, size: size)
        return NotificationPage(items: items, fetchedCount: items.count)
    }
}
