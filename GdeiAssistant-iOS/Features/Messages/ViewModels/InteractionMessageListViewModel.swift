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

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

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
            async let itemsTask = fetchNextNonEmptyPage(from: 0)
            async let unreadTask = repository.fetchInteractionUnreadCount()

            let page = try await itemsTask
            items = page.items
            interactionUnreadCount = (try? await unreadTask) ?? page.items.filter { !$0.isRead }.count
            nextStart = page.nextStart
            canLoadMore = page.canLoadMore
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
            let page = try await fetchNextNonEmptyPage(from: nextStart)
            items.append(contentsOf: page.items)
            nextStart = page.nextStart
            canLoadMore = page.canLoadMore
        } catch {
            loadMoreErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("messages.interactionLoadFailed")
        }
    }

    private func fetchNextNonEmptyPage(from start: Int) async throws -> (items: [AppNotificationItem], nextStart: Int, canLoadMore: Bool) {
        var cursor = start
        var remainingAttempts = 5

        while remainingAttempts > 0 {
            remainingAttempts -= 1
            let page = try await repository.fetchInteractionBatch(start: cursor, size: pageSize)
            cursor += page.fetchedCount
            let hasMore = page.fetchedCount == pageSize
            if !page.items.isEmpty || !hasMore {
                return (page.items, cursor, hasMore)
            }
        }

        return ([], cursor, true)
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
