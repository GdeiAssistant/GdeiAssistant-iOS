import Foundation
import Combine

@MainActor
final class InteractionMessageListViewModel: ObservableObject {
    @Published var items: [AppNotificationItem] = []
    @Published var interactionUnreadCount = 0
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var canLoadMore = true
    @Published var errorMessage: String?
    @Published var loadMoreErrorMessage: String?

    private let repository: any MessagesRepository
    private let pageSize = 5
    private var nextStart = 0

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        loadMoreErrorMessage = nil
        nextStart = 0
        canLoadMore = true
        defer { isLoading = false }

        do {
            async let itemsTask = repository.fetchInteractionNotifications(start: 0, size: pageSize)
            async let unreadTask = repository.fetchInteractionUnreadCount()

            let page = try await itemsTask
            items = page
            interactionUnreadCount = (try? await unreadTask) ?? page.filter { !$0.isRead }.count
            nextStart = page.count
            canLoadMore = page.count == pageSize
        } catch {
            items = []
            interactionUnreadCount = 0
            canLoadMore = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed")
        }
    }

    func loadMoreIfNeeded(currentItem item: AppNotificationItem) async {
        guard canLoadMore, !isLoadingMore, items.last?.id == item.id else { return }

        isLoadingMore = true
        loadMoreErrorMessage = nil
        defer { isLoadingMore = false }

        do {
            let page = try await repository.fetchInteractionNotifications(start: nextStart, size: pageSize)
            items.append(contentsOf: page)
            nextStart += page.count
            canLoadMore = page.count == pageSize
        } catch {
            loadMoreErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed")
        }
    }

    func markNotificationRead(notificationID: String) async {
        guard let index = items.firstIndex(where: { $0.id == notificationID && !$0.isRead }) else {
            return
        }

        do {
            try await repository.markNotificationRead(notificationID: notificationID)
            items[index] = items[index].updatingReadState(true)
            interactionUnreadCount = max(0, interactionUnreadCount - 1)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
        }
    }

    func markAllNotificationsRead() async {
        guard interactionUnreadCount > 0 else { return }

        do {
            try await repository.markAllNotificationsRead()
            items = items.map { item in
                item.isInteractionItem ? item.updatingReadState(true) : item
            }
            interactionUnreadCount = 0
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.updateStatusFailed")
        }
    }
}
