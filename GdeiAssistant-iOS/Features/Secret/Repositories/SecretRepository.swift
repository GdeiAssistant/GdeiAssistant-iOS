import Foundation

@MainActor
protocol SecretRepository {
    func fetchPosts() async throws -> [SecretPost]
    func fetchMyPosts(start: Int, size: Int) async throws -> [SecretPost]
    func fetchDetail(postID: String) async throws -> SecretPostDetail
    func publish(draft: SecretDraft) async throws
    func submitComment(postID: String, content: String) async throws
    func setLike(postID: String, liked: Bool) async throws
}
