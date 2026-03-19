import Foundation
import Combine

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var systemNoticeItems: [AppNotificationItem] = []
    @Published var interactionNoticeItems: [AppNotificationItem] = []

    @Published var isNewsLoading = false
    @Published var isSystemLoading = false
    @Published var isInteractionLoading = false

    @Published var newsErrorMessage: String?
    @Published var systemErrorMessage: String?
    @Published var interactionErrorMessage: String?

    @Published var interactionUnreadCount = 0

    private let newsRepository: any NewsRepository
    private let messagesRepository: any MessagesRepository
    private let overviewLimit = 3

    init(
        newsRepository: any NewsRepository,
        messagesRepository: any MessagesRepository
    ) {
        self.newsRepository = newsRepository
        self.messagesRepository = messagesRepository
    }

    var isInitialLoading: Bool {
        if hasAnyContent {
            return false
        }
        return isNewsLoading || isSystemLoading || isInteractionLoading
    }

    var hasAnyError: Bool {
        newsErrorMessage != nil || systemErrorMessage != nil || interactionErrorMessage != nil
    }

    var primaryErrorMessage: String {
        newsErrorMessage
            ?? systemErrorMessage
            ?? interactionErrorMessage
            ?? "加载资讯信息失败"
    }

    var hasAnyContent: Bool {
        !newsItems.isEmpty || !systemNoticeItems.isEmpty || !interactionNoticeItems.isEmpty
    }

    func loadIfNeeded() async {
        guard !hasAnyContent else { return }
        await refresh()
    }

    func refresh() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshNews() }
            group.addTask { await self.refreshSystemNotices() }
            group.addTask { await self.refreshInteractionItems() }
        }
    }

    func refreshNews() async {
        isNewsLoading = true
        newsErrorMessage = nil
        defer { isNewsLoading = false }

        do {
            newsItems = try await newsRepository.fetchNews(start: 0, size: overviewLimit)
        } catch {
            newsItems = []
            newsErrorMessage = (error as? LocalizedError)?.errorDescription ?? "新闻通知加载失败"
        }
    }

    func refreshSystemNotices() async {
        isSystemLoading = true
        systemErrorMessage = nil
        defer { isSystemLoading = false }

        do {
            systemNoticeItems = try await messagesRepository.fetchAnnouncementPage(start: 0, size: overviewLimit)
        } catch {
            systemNoticeItems = []
            systemErrorMessage = (error as? LocalizedError)?.errorDescription ?? "系统通知公告加载失败"
        }
    }

    func refreshInteractionItems() async {
        isInteractionLoading = true
        interactionErrorMessage = nil
        defer { isInteractionLoading = false }

        do {
            async let itemsTask = messagesRepository.fetchInteractionNotifications(start: 0, size: overviewLimit)
            async let unreadTask = messagesRepository.fetchInteractionUnreadCount()

            let items = try await itemsTask
            interactionNoticeItems = items
            interactionUnreadCount = (try? await unreadTask) ?? items.filter { !$0.isRead }.count
        } catch {
            interactionNoticeItems = []
            interactionUnreadCount = 0
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? "互动消息加载失败"
        }
    }

    func markNotificationRead(notificationID: String) async {
        guard let index = interactionNoticeItems.firstIndex(where: { $0.id == notificationID && !$0.isRead }) else {
            return
        }

        do {
            try await messagesRepository.markNotificationRead(notificationID: notificationID)
            interactionNoticeItems[index] = interactionNoticeItems[index].updatingReadState(true)
            interactionUnreadCount = max(0, interactionUnreadCount - 1)
        } catch {
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? "更新消息状态失败"
        }
    }

    func markAllInteractionNotificationsRead() async {
        guard interactionUnreadCount > 0 else { return }

        do {
            try await messagesRepository.markAllNotificationsRead()
            interactionNoticeItems = interactionNoticeItems.map { item in
                item.isInteractionItem ? item.updatingReadState(true) : item
            }
            interactionUnreadCount = 0
        } catch {
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? "更新消息状态失败"
        }
    }
}
