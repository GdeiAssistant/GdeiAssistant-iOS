import Foundation

@MainActor
protocol SecretRepository {
    func fetchPosts() async throws -> [SecretPost]
    func fetchMyPosts() async throws -> [SecretPost]
    func fetchDetail(postID: String) async throws -> SecretPostDetail
    func publish(draft: SecretDraft) async throws
    func submitComment(postID: String, content: String) async throws
    func setLike(postID: String, liked: Bool) async throws
}

@MainActor
final class SwitchingSecretRepository: SecretRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any SecretRepository
    private let mockRepository: any SecretRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any SecretRepository,
        mockRepository: any SecretRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchPosts() async throws -> [SecretPost] {
        try await currentRepository.fetchPosts()
    }

    func fetchMyPosts() async throws -> [SecretPost] {
        try await currentRepository.fetchMyPosts()
    }

    func fetchDetail(postID: String) async throws -> SecretPostDetail {
        try await currentRepository.fetchDetail(postID: postID)
    }

    func publish(draft: SecretDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func submitComment(postID: String, content: String) async throws {
        try await currentRepository.submitComment(postID: postID, content: content)
    }

    func setLike(postID: String, liked: Bool) async throws {
        try await currentRepository.setLike(postID: postID, liked: liked)
    }

    private var currentRepository: any SecretRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
