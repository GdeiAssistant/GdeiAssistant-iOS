import Foundation

@MainActor
protocol TopicRepository {
    func fetchPosts(start: Int, size: Int) async throws -> [TopicPost]
    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [TopicPost]
    func fetchMyPosts(start: Int, size: Int) async throws -> [TopicPost]
    func fetchDetail(postID: String) async throws -> TopicPostDetail
    func publish(draft: TopicDraft) async throws
    func like(postID: String) async throws
}

@MainActor
final class SwitchingTopicRepository: TopicRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any TopicRepository
    private let mockRepository: any TopicRepository

    init(environment: AppEnvironment, remoteRepository: any TopicRepository, mockRepository: any TopicRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchPosts(start: Int, size: Int) async throws -> [TopicPost] {
        try await currentRepository.fetchPosts(start: start, size: size)
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [TopicPost] {
        try await currentRepository.searchPosts(keyword: keyword, start: start, size: size)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [TopicPost] {
        try await currentRepository.fetchMyPosts(start: start, size: size)
    }

    func fetchDetail(postID: String) async throws -> TopicPostDetail {
        try await currentRepository.fetchDetail(postID: postID)
    }

    func publish(draft: TopicDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func like(postID: String) async throws {
        try await currentRepository.like(postID: postID)
    }

    private var currentRepository: any TopicRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
