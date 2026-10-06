import Foundation
import Combine

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published private(set) var conversations: [ConversationSummary] = []
    @Published private(set) var unreadTotal = 0
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private let realtimeManager: any SocialRealtimeManaging
    private var nextCursor: String?
    private var pollTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?

    init(repository: any SocialRepository, realtimeManager: any SocialRealtimeManaging) {
        self.repository = repository
        self.realtimeManager = realtimeManager
    }

    func start() async {
        await reload()
        startPolling()
        observeRealtime()
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        eventTask?.cancel()
        eventTask = nil
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            conversations = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            unreadTotal = unread.total
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.conversations.loadFailed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchConversations(cursor: nextCursor, limit: 20)
            var seen = Set(conversations.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                conversations.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.conversations.loadFailed")
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self, !Task.isCancelled else { return }
                await self.reloadQuietly()
            }
        }
    }

    private func observeRealtime() {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            guard let self else { return }
            var lastEvent = self.realtimeManager.latestEvent
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                let current = self.realtimeManager.latestEvent
                if current != lastEvent {
                    lastEvent = current
                    await self.reloadQuietly()
                }
            }
        }
    }

    private func reloadQuietly() async {
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            conversations = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            unreadTotal = unread.total
        } catch {
            // Keep existing list on background refresh failure.
        }
    }
}
