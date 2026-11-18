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
    @Published var festival: Festival?

    private var newsRepository: any NewsRepository
    private var messagesRepository: any MessagesRepository
    private let overviewLimit = 3
    private var repositoryGeneration = 0

    init(
        newsRepository: any NewsRepository,
        messagesRepository: any MessagesRepository
    ) {
        self.newsRepository = newsRepository
        self.messagesRepository = messagesRepository
    }

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func updateRepositories(
        newsRepository: any NewsRepository,
        messagesRepository: any MessagesRepository
    ) {
        repositoryGeneration += 1
        self.newsRepository = newsRepository
        self.messagesRepository = messagesRepository
        isNewsLoading = false
        isSystemLoading = false
        isInteractionLoading = false
        newsItems = []
        systemNoticeItems = []
        interactionNoticeItems = []
        newsErrorMessage = nil
        systemErrorMessage = nil
        interactionErrorMessage = nil
        interactionUnreadCount = 0
        festival = nil
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
        let generation = repositoryGeneration
        isNewsLoading = true
        newsErrorMessage = nil
        defer { if generation == repositoryGeneration { isNewsLoading = false } }

        do {
            let items = try await newsRepository.fetchNews(start: 0, size: overviewLimit)
            guard generation == repositoryGeneration else { return }
            newsItems = items
        } catch {
            guard generation == repositoryGeneration else { return }
            newsItems = []
            newsErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.newsLoadFailed")
        }
    }

    func refreshSystemNotices() async {
        let generation = repositoryGeneration
        isSystemLoading = true
        systemErrorMessage = nil
        defer { if generation == repositoryGeneration { isSystemLoading = false } }

        do {
            let items = try await messagesRepository.fetchAnnouncementPage(start: 0, size: overviewLimit)
            guard generation == repositoryGeneration else { return }
            systemNoticeItems = items
        } catch {
            guard generation == repositoryGeneration else { return }
            systemNoticeItems = []
            systemErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.systemNoticeLoadFailed")
        }
    }

    func refreshInteractionItems() async {
        let generation = repositoryGeneration
        isInteractionLoading = true
        interactionErrorMessage = nil
        defer { if generation == repositoryGeneration { isInteractionLoading = false } }

        do {
            async let itemsTask = messagesRepository.fetchInteractionNotifications(start: 0, size: overviewLimit)
            async let unreadTask = messagesRepository.fetchInteractionUnreadCount()

            let items = try await itemsTask
            let unread = try? await unreadTask
            guard generation == repositoryGeneration else { return }
            interactionNoticeItems = items
            interactionUnreadCount = unread ?? items.filter { !$0.isRead }.count
        } catch {
            guard generation == repositoryGeneration else { return }
            interactionNoticeItems = []
            interactionUnreadCount = 0
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed")
        }
    }

    func refreshFestival() async {
        let generation = repositoryGeneration
        let loadedFestival = try? await messagesRepository.fetchFestival()
        guard generation == repositoryGeneration else { return }
        festival = loadedFestival
    }

    func markNotificationRead(notificationID: String) async {
        guard interactionNoticeItems.contains(where: { $0.id == notificationID && !$0.isRead }) else {
            return
        }
        let generation = repositoryGeneration

        do {
            try await messagesRepository.markNotificationRead(notificationID: notificationID)
            guard generation == repositoryGeneration,
                  let index = interactionNoticeItems.firstIndex(where: { $0.id == notificationID && !$0.isRead }) else {
                return
            }
            interactionNoticeItems[index] = interactionNoticeItems[index].updatingReadState(true)
            interactionUnreadCount = max(0, interactionUnreadCount - 1)
        } catch {
            guard generation == repositoryGeneration else { return }
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
        }
    }

    func markAllInteractionNotificationsRead() async {
        guard interactionUnreadCount > 0 else { return }
        let generation = repositoryGeneration

        do {
            try await messagesRepository.markAllNotificationsRead()
            guard generation == repositoryGeneration else { return }
            interactionNoticeItems = interactionNoticeItems.map { item in
                item.isInteractionItem ? item.updatingReadState(true) : item
            }
            interactionUnreadCount = 0
        } catch {
            guard generation == repositoryGeneration else { return }
            interactionErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
        }
    }
}
