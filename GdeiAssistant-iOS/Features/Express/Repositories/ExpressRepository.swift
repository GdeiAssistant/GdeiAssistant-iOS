import Foundation

@MainActor
protocol ExpressRepository {
    func fetchPosts(start: Int, size: Int) async throws -> [ExpressPost]
    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [ExpressPost]
    func fetchMyPosts(start: Int, size: Int) async throws -> [ExpressPost]
    func fetchDetail(postID: String) async throws -> ExpressPostDetail
    func fetchComments(postID: String) async throws -> [ExpressCommentItem]
    func publish(draft: ExpressDraft) async throws
    func submitComment(postID: String, content: String) async throws
    func like(postID: String) async throws
    func guess(postID: String, name: String) async throws -> Bool
}

@MainActor
final class SwitchingExpressRepository: ExpressRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any ExpressRepository
    private let mockRepository: any ExpressRepository

    init(environment: AppEnvironment, remoteRepository: any ExpressRepository, mockRepository: any ExpressRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        try await currentRepository.fetchPosts(start: start, size: size)
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [ExpressPost] {
        try await currentRepository.searchPosts(keyword: keyword, start: start, size: size)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        try await currentRepository.fetchMyPosts(start: start, size: size)
    }

    func fetchDetail(postID: String) async throws -> ExpressPostDetail {
        try await currentRepository.fetchDetail(postID: postID)
    }

    func fetchComments(postID: String) async throws -> [ExpressCommentItem] {
        try await currentRepository.fetchComments(postID: postID)
    }

    func publish(draft: ExpressDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func submitComment(postID: String, content: String) async throws {
        try await currentRepository.submitComment(postID: postID, content: content)
    }

    func like(postID: String) async throws {
        try await currentRepository.like(postID: postID)
    }

    func guess(postID: String, name: String) async throws -> Bool {
        try await currentRepository.guess(postID: postID, name: name)
    }

    private var currentRepository: any ExpressRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
