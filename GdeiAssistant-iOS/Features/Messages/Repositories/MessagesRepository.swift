import Foundation

@MainActor
protocol MessagesRepository {
    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem]
    func fetchInteractionUnreadCount() async throws -> Int
    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem
    func markNotificationRead(notificationID: String) async throws
    func markAllNotificationsRead() async throws
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

    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await currentRepository.fetchAnnouncementPage(start: start, size: size)
    }

    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await currentRepository.fetchInteractionNotifications(start: start, size: size)
    }

    func fetchInteractionUnreadCount() async throws -> Int {
        try await currentRepository.fetchInteractionUnreadCount()
    }

    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem {
        try await currentRepository.fetchAnnouncementDetail(id: id)
    }

    func markNotificationRead(notificationID: String) async throws {
        try await currentRepository.markNotificationRead(notificationID: notificationID)
    }

    func markAllNotificationsRead() async throws {
        try await currentRepository.markAllNotificationsRead()
    }

    private var currentRepository: any MessagesRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
