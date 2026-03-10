import Foundation

@MainActor
final class RemoteMessagesRepository: MessagesRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchNotifications() async throws -> [AppNotificationItem] {
        let announcement: AnnouncementRemoteDTO? = try? await apiClient.get("/announcement", requiresAuth: true)
        let information: InformationRemoteDTO? = try? await apiClient.get("/information/list", requiresAuth: true)
        let interactionItems: [InteractionNotificationRemoteDTO] = (try? await apiClient.get(
            "/message/interaction/start/0/size/20",
            requiresAuth: true
        )) ?? []
        return MessagesRemoteMapper.mapNotifications(
            announcement: announcement,
            information: information,
            interactionItems: interactionItems
        )
    }

    func fetchThreads() async throws -> [InteractionThreadItem] {
        let dtos: [DatingMessageDTO] = (try? await apiClient.get("/dating/message/start/0", requiresAuth: true)) ?? []
        return MessagesRemoteMapper.mapThreads(dtos)
    }

    func markThreadRead(threadID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/dating/message/id/\(threadID)/read", requiresAuth: true)
    }
}
