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

@MainActor
final class SwitchingCommunityRepository: CommunityRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any CommunityRepository
    private let mockRepository: any CommunityRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any CommunityRepository,
        mockRepository: any CommunityRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchPosts(sort: CommunityFeedSort) async throws -> [CommunityPost] {
        try await currentRepository.fetchPosts(sort: sort)
    }

    func fetchPostDetail(postID: String) async throws -> CommunityPostDetail {
        try await currentRepository.fetchPostDetail(postID: postID)
    }

    func fetchComments(postID: String) async throws -> [CommunityComment] {
        try await currentRepository.fetchComments(postID: postID)
    }

    func submitComment(postID: String, content: String) async throws {
        try await currentRepository.submitComment(postID: postID, content: content)
    }

    func toggleLike(postID: String) async throws {
        try await currentRepository.toggleLike(postID: postID)
    }

    func fetchTopic(topicID: String) async throws -> CommunityTopic {
        try await currentRepository.fetchTopic(topicID: topicID)
    }

    func fetchTopicPosts(topicID: String, sort: CommunityFeedSort) async throws -> [CommunityPost] {
        try await currentRepository.fetchTopicPosts(topicID: topicID, sort: sort)
    }

    private var currentRepository: any CommunityRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
