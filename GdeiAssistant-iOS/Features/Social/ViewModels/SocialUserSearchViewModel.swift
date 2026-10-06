import Foundation
import Combine

@MainActor
final class SocialUserSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private var nextCursor: String?
    private var searchTask: Task<Void, Never>?

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func search() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await reload()
        }
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.searchUsers(query: query, cursor: nil, limit: 20)
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.search.failed")
        }
    }

    func loadMoreIfNeeded(currentItem: SocialUser?) async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        guard let currentItem, currentItem.id == users.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await repository.searchUsers(query: query, cursor: nextCursor, limit: 20)
            users = mergeUnique(users, page.items)
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.search.failed")
        }
    }

    private func mergeUnique(_ existing: [SocialUser], _ incoming: [SocialUser]) -> [SocialUser] {
        var seen = Set(existing.map(\.id))
        var result = existing
        for item in incoming where !seen.contains(item.id) {
            seen.insert(item.id)
            result.append(item)
        }
        return result
    }
}
