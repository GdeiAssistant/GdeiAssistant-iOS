import Foundation

@MainActor
final class RemoteCommunityRepository: CommunityRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPosts(sort: CommunityFeedSort) async throws -> [CommunityPost] {
        let dtos: [ExpressPostDTO] = try await apiClient.get("/express/start/0/size/20", requiresAuth: true)
        return CommunityRemoteMapper.mapPosts(dtos, sort: sort)
    }

    func fetchPostDetail(postID: String) async throws -> CommunityPostDetail {
        let dto: ExpressPostDTO = try await apiClient.get("/express/id/\(postID)", requiresAuth: true)
        return CommunityRemoteMapper.mapPostDetail(dto)
    }

    func fetchComments(postID: String) async throws -> [CommunityComment] {
        let dtos: [ExpressCommentDTO] = try await apiClient.get("/express/id/\(postID)/comment", requiresAuth: true)
        return CommunityRemoteMapper.mapComments(dtos)
    }

    func submitComment(postID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/express/id/\(postID)/comment",
            queryItems: [URLQueryItem(name: "comment", value: content)],
            requiresAuth: true
        )
    }

    func toggleLike(postID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/express/id/\(postID)/like", requiresAuth: true)
    }

    func fetchTopic(topicID: String) async throws -> CommunityTopic {
        CommunityRemoteMapper.mapTopic(keyword: topicID)
    }

    func fetchTopicPosts(topicID: String, sort: CommunityFeedSort) async throws -> [CommunityPost] {
        let encodedKeyword = topicID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? topicID
        let dtos: [TopicPostDTO] = try await apiClient.get(
            "/topic/keyword/\(encodedKeyword)/start/0/size/20",
            requiresAuth: true
        )
        return CommunityRemoteMapper.mapTopicPosts(dtos, keyword: topicID, sort: sort)
    }
}
