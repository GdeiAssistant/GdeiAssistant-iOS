import Foundation

@MainActor
final class MockMessagesRepository: MessagesRepository {
    private var announcementItems = MockFactory.makeNotifications().filter { $0.destination == .announcement }
    private var interactionItems = MockFactory.makeNotifications().filter(\.isInteractionItem)
    private let announcementDetailsByID = MockFactory.makeAnnouncementDetailsByID()

    func fetchAnnouncementPage(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < announcementItems.count else { return [] }
        return Array(announcementItems.dropFirst(safeStart).prefix(safeSize))
    }

    func fetchInteractionNotifications(start: Int, size: Int) async throws -> [AppNotificationItem] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < interactionItems.count else { return [] }
        return Array(interactionItems.dropFirst(safeStart).prefix(safeSize))
    }

    func fetchInteractionUnreadCount() async throws -> Int {
        interactionItems.filter { !$0.isRead }.count
    }

    func fetchAnnouncementDetail(id: String) async throws -> AnnouncementDetailItem {
        if let detail = announcementDetailsByID[id] {
            return detail
        }

        throw NetworkError.server(code: 404, message: "公告不存在")
    }

    func markNotificationRead(notificationID: String) async throws {
        guard let index = interactionItems.firstIndex(where: { $0.id == notificationID }), !interactionItems[index].isRead else {
            return
        }

        interactionItems[index] = interactionItems[index].updatingReadState(true)
    }

    func markAllNotificationsRead() async throws {
        interactionItems = interactionItems.map { item in
            guard !item.isRead else {
                return item
            }

            return item.updatingReadState(true)
        }
    }
}
