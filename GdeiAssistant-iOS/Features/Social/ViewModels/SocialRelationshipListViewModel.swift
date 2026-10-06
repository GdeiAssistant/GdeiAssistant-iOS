import Foundation
import Combine

@MainActor
final class SocialRelationshipListViewModel: ObservableObject {
    @Published private(set) var users: [SocialUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    let userID: String
    let kind: SocialRelationshipKind
    private let repository: any SocialRepository
    private var nextCursor: String?

    init(userID: String, kind: SocialRelationshipKind, repository: any SocialRepository) {
        self.userID = userID
        self.kind = kind
        self.repository = repository
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await repository.fetchRelationships(
                userID: userID,
                kind: kind,
                cursor: nil,
                limit: 20
            )
            users = page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.list.loadFailed")
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        do {
            let page = try await repository.fetchRelationships(
                userID: userID,
                kind: kind,
                cursor: nextCursor,
                limit: 20
            )
            var seen = Set(users.map(\.id))
            for item in page.items where !seen.contains(item.id) {
                seen.insert(item.id)
                users.append(item)
            }
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.list.loadFailed")
        }
    }
}
