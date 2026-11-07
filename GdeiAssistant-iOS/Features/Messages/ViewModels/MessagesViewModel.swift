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

    @Published var interactionUnreadCount = 0 {
        didSet {
            if unreadBadgeStore.sessionRevision == badgeSessionRevision {
                unreadBadgeStore.updateInteractionUnread(interactionUnreadCount)
            }
        }
    }
    @Published var festival: Festival?

    private let newsRepository: any NewsRepository
    private let messagesRepository: any MessagesRepository
    private let socialRepository: any SocialRepository
    private let unreadBadgeStore: UnreadBadgeStore
    private let badgeSessionRevision: Int
    private let overviewLimit = 3

    init(
        newsRepository: any NewsRepository,
        messagesRepository: any MessagesRepository,
        socialRepository: any SocialRepository,
        unreadBadgeStore: UnreadBadgeStore
    ) {
        self.newsRepository = newsRepository
        self.messagesRepository = messagesRepository
        self.socialRepository = socialRepository
        self.unreadBadgeStore = unreadBadgeStore
        self.badgeSessionRevision = unreadBadgeStore.sessionRevision
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
            ?? localizedString("messages.loadFailed")
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
            group.addTask { await self.refreshFestival() }
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
            newsErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.newsLoadFailed")
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
            systemErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.systemNoticeLoadFailed")
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
            do { interactionUnreadCount = try await unreadTask }
            catch { interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed") }
        } catch {
            // A failed refresh keeps the last known unread total.
            interactionNoticeItems = []
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed")
        }
    }

    func refreshFestival() async {
        festival = try? await messagesRepository.fetchFestival()
    }

    /// Refreshes both unread counters feeding the tab badge without touching list content.
    func refreshUnreadBadge() async {
        async let interactionTask = messagesRepository.fetchInteractionUnreadCount()
        async let directMessageTask = socialRepository.fetchUnreadCount()

        if let count = try? await interactionTask {
            interactionUnreadCount = count
        }
        if let unread = try? await directMessageTask,
           unreadBadgeStore.sessionRevision == badgeSessionRevision {
            unreadBadgeStore.updateDirectMessageUnread(unread.total)
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
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
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
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
        }
    }
}
