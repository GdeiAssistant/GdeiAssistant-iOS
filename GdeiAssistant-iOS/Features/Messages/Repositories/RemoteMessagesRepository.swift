import Foundation

@MainActor
final class RemoteMessagesRepository: MessagesRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem] {
        let announcements: [AnnouncementRemoteDTO] = try await apiClient.get(
            "/information/announcement/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return MessagesRemoteMapper.mapAnnouncementItems(announcements)
    }

    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem] {
        let items: [InteractionNotificationRemoteDTO] = try await apiClient.get(
            "/information/message/interaction/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return MessagesRemoteMapper.mapInteractionItems(items)
    }

    func fetchInteractionUnreadCount() async throws -> Int {
        let unreadCount: Int = try await apiClient.get("/information/message/unread", requiresAuth: true)
        return max(unreadCount, 0)
    }

    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem {
        let dto: AnnouncementRemoteDTO = try await apiClient.get("/information/announcement/id/\(id)", requiresAuth: true)
        return MessagesRemoteMapper.mapAnnouncementDetail(dto)
    }

    func markNotificationRead(notificationID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/information/message/id/\(notificationID)/read", requiresAuth: true)
    }

    func markAllNotificationsRead() async throws {
        let _: EmptyPayload = try await apiClient.post("/information/message/readall", requiresAuth: true)
    }
}
