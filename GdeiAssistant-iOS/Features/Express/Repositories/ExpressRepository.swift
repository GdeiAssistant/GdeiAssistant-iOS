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
