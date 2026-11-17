import Foundation

@MainActor
final class RemoteMessagesRepository: MessagesRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await fetchAnnouncementBatch(start: start, size: size).items
    }

    func fetchAnnouncementBatch(start: Int, size: Int) async throws -> NotificationPage {
        let announcements: [AnnouncementRemoteDTO] = try await apiClient.get(
            "/information/announcement/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return NotificationPage(
            items: MessagesRemoteMapper.mapAnnouncementItems(announcements),
            fetchedCount: announcements.count
        )
    }

    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await fetchInteractionBatch(start: start, size: size).items
    }

    func fetchInteractionBatch(start: Int, size: Int) async throws -> NotificationPage {
        let items: [InteractionNotificationRemoteDTO] = try await apiClient.get(
            "/information/message/interaction/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return NotificationPage(
            items: MessagesRemoteMapper.mapInteractionItems(items),
            fetchedCount: items.count
        )
    }

    func fetchInteractionUnreadCount() async throws -> Int {
        let unreadCount: Int = try await apiClient.get("/information/message/unread", requiresAuth: true)
        return max(unreadCount, 0)
    }

    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem {
        let dto: AnnouncementRemoteDTO = try await apiClient.get("/information/announcement/\(id)", requiresAuth: true)
        return try MessagesRemoteMapper.mapAnnouncementDetail(dto, fallbackID: id)
    }

    func fetchFestival() async throws -> Festival? {
        let info: InformationRemoteDTO = try await apiClient.get("/information/overview", requiresAuth: true)
        return MessagesRemoteMapper.mapFestival(info.festival)
    }

    func markNotificationRead(notificationID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/information/message/\(notificationID)/read", requiresAuth: true)
    }

    func markAllNotificationsRead() async throws {
        let _: EmptyPayload = try await apiClient.post("/information/message/readall", requiresAuth: true)
    }
}
