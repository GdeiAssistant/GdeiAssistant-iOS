import Foundation
import Combine

@MainActor
final class SocialBlockListViewModel: ObservableObject {
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository
    private var nextCursor: String?

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.fetchBlocks(cursor: nil, limit: 20)
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.blockList.loadFailed")
        }
    }

    func unblock(_ user: SocialUser) async {
        do {
            _ = try await repository.unblock(userID: user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchBlocks(cursor: nextCursor, limit: 20)
            var seen = Set(users.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                users.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.blockList.loadFailed")
        }
    }
}
