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
