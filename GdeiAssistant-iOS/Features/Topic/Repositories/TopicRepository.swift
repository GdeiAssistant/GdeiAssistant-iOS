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
