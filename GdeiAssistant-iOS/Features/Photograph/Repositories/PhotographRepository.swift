import Foundation

@MainActor
protocol PhotographRepository {
    func fetchStats() async throws -> PhotographStats
    func fetchPosts(category: PhotographCategory, start: Int, size: Int) async throws -> [PhotographPost]
    func fetchMyPosts(start: Int, size: Int) async throws -> [PhotographPost]
    func fetchDetail(postID: String) async throws -> PhotographPostDetail
    func fetchComments(postID: String) async throws -> [PhotographCommentItem]
    func publish(draft: PhotographDraft) async throws
    func like(postID: String) async throws
    func submitComment(postID: String, content: String) async throws
}

@MainActor
final class SwitchingPhotographRepository: PhotographRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any PhotographRepository
    private let mockRepository: any PhotographRepository

    init(environment: AppEnvironment, remoteRepository: any PhotographRepository, mockRepository: any PhotographRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchStats() async throws -> PhotographStats {
        try await currentRepository.fetchStats()
    }

    func fetchPosts(category: PhotographCategory, start: Int, size: Int) async throws -> [PhotographPost] {
        try await currentRepository.fetchPosts(category: category, start: start, size: size)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [PhotographPost] {
        try await currentRepository.fetchMyPosts(start: start, size: size)
    }

    func fetchDetail(postID: String) async throws -> PhotographPostDetail {
        try await currentRepository.fetchDetail(postID: postID)
    }

    func fetchComments(postID: String) async throws -> [PhotographCommentItem] {
        try await currentRepository.fetchComments(postID: postID)
    }

    func publish(draft: PhotographDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func like(postID: String) async throws {
        try await currentRepository.like(postID: postID)
    }

    func submitComment(postID: String, content: String) async throws {
        try await currentRepository.submitComment(postID: postID, content: content)
    }

    private var currentRepository: any PhotographRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
