import Foundation

@MainActor
protocol MessagesRepository {
    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchInteractionUnreadCount() async throws -> Int
    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem
    func fetchFestival() async throws -> Festival?
    func markNotificationRead(notificationID: String) async throws
    func markAllNotificationsRead() async throws
}
