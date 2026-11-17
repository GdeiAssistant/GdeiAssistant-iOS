import Foundation

enum CommunityFeedSort: String, CaseIterable, Identifiable {
    case hot
    case latest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hot:
            return localizedString("community.sort.hot")
        case .latest:
            return localizedString("community.sort.latest")
        }
    }
}

@MainActor
protocol CommunityRepository {
    func fetchPosts(sort: CommunityFeedSort) async throws -> [CommunityPost]
    func fetchPostDetail(postID: String) async throws -> CommunityPostDetail
    func fetchComments(postID: String) async throws -> [CommunityComment]
    func submitComment(postID: String, content: String) async throws
    func toggleLike(postID: String) async throws
    func fetchTopic(topicID: String) async throws -> CommunityTopic
    func fetchTopicPosts(topicID: String, sort: CommunityFeedSort) async throws -> [CommunityPost]
}
