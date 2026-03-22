import Foundation
import Combine

@MainActor
final class CommunityFeedViewModel: ObservableObject {
    @Published var selectedSort: CommunityFeedSort = .hot
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any CommunityRepository
    private var hasLoaded = false

    init(repository: any CommunityRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadPosts()
    }

    func loadPosts() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            posts = try await repository.fetchPosts(sort: selectedSort)
        } catch {
            posts = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("community.vm.feedLoadFailed")
        }
    }

    func refresh() async {
        await loadPosts()
    }

    func changeSort(_ sort: CommunityFeedSort) async {
        guard selectedSort != sort else { return }
        selectedSort = sort
        await loadPosts()
    }
}
