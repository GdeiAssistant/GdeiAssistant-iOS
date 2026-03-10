import Foundation
import Combine

@MainActor
final class SecretViewModel: ObservableObject {
    @Published var posts: [SecretPost] = []
    @Published var myPosts: [SecretPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any SecretRepository

    init(repository: any SecretRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard posts.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let postsTask = repository.fetchPosts()
            async let myPostsTask = repository.fetchMyPosts()
            posts = try await postsTask
            myPosts = try await myPostsTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "树洞内容加载失败"
        }
    }

    func fetchDetail(postID: String) async throws -> SecretPostDetail {
        try await repository.fetchDetail(postID: postID)
    }

    func publish(draft: SecretDraft) async throws {
        try await repository.publish(draft: draft)
        await refresh()
    }

    func submitComment(postID: String, content: String) async throws -> SecretPostDetail {
        try await repository.submitComment(postID: postID, content: content)
        let detail = try await repository.fetchDetail(postID: postID)
        syncPost(detail.post)
        return detail
    }

    func setLike(postID: String, liked: Bool) async throws -> SecretPostDetail {
        try await repository.setLike(postID: postID, liked: liked)
        let detail = try await repository.fetchDetail(postID: postID)
        syncPost(detail.post)
        return detail
    }

    private func syncPost(_ post: SecretPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        }
    }
}
