import Foundation
import Combine

@MainActor
final class TopicFeedViewModel: ObservableObject {
    @Published var selectedSort: CommunityFeedSort = .hot
    @Published var topic: CommunityTopic?
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let topicID: String

    private let repository: any CommunityRepository

    init(topicID: String, repository: any CommunityRepository) {
        self.topicID = topicID
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard topic == nil && posts.isEmpty else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let topicTask = repository.fetchTopic(topicID: topicID)
            async let postsTask = repository.fetchTopicPosts(topicID: topicID, sort: selectedSort)
            topic = try await topicTask
            posts = try await postsTask
        } catch {
            topic = nil
            posts = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("community.vm.topicLoadFailed")
        }
    }

    func changeSort(_ sort: CommunityFeedSort) async {
        guard selectedSort != sort else { return }
        selectedSort = sort
        await load()
    }
}
