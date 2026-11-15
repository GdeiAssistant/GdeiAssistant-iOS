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
    private var quietReloadTask: Task<Void, Never>?
    private var eventCancellable: AnyCancellable?
    private var isReloadingQuietly = false
    private var hasPendingQuietReload = false
    private var reloadGeneration: UInt64 = 0

    init(repository: any SocialRepository, realtimeManager: any SocialRealtimeManaging) {
        self.repository = repository
        self.realtimeManager = realtimeManager
    }

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func start() async {
        await reload()
        startPolling()
        observeRealtime()
    }

    func stop() {
        reloadGeneration &+= 1
        pollTask?.cancel()
        pollTask = nil
        quietReloadTask?.cancel()
        quietReloadTask = nil
        eventCancellable?.cancel()
        eventCancellable = nil
        isReloadingQuietly = false
        hasPendingQuietReload = false
    }

    func reload() async {
        reloadGeneration &+= 1
        let generation = reloadGeneration
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            guard generation == reloadGeneration else { return }
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
                self.scheduleQuietReload()
            }
        }
    }

    private func observeRealtime() {
        eventCancellable?.cancel()
        eventCancellable = realtimeManager.eventPublisher.sink { [weak self] _ in
            self?.scheduleQuietReload()
        }
    }

    private func scheduleQuietReload() {
        if isReloadingQuietly {
            hasPendingQuietReload = true
            return
        }
        isReloadingQuietly = true
        hasPendingQuietReload = false
        quietReloadTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isReloadingQuietly = false
                self.hasPendingQuietReload = false
                self.quietReloadTask = nil
            }
            repeat {
                self.hasPendingQuietReload = false
                await self.reloadQuietly()
            } while !Task.isCancelled && self.hasPendingQuietReload
        }
    }

    private func reloadQuietly() async {
        let generation = reloadGeneration
        do {
            async let pageTask = repository.fetchConversations(cursor: nil, limit: 20)
            async let unreadTask = repository.fetchUnreadCount()
            let page = try await pageTask
            let unread = try await unreadTask
            guard !Task.isCancelled, generation == reloadGeneration else { return }
            conversations = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
            unreadTotal = unread.total
        } catch {
            // Keep existing list on background refresh failure.
        }
    }
}
