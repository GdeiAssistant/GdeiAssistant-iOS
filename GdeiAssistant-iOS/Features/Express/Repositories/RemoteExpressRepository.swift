import Foundation

@MainActor
final class RemoteExpressRepository: ExpressRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        let dtos: [ExpressRemoteDTO] = try await apiClient.get(
            "/express/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return dtos.map(ExpressRemoteMapper.mapPost)
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [ExpressPost] {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? keyword
        let dtos: [ExpressRemoteDTO] = try await apiClient.get(
            "/express/keyword/\(encodedKeyword)/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return dtos.map(ExpressRemoteMapper.mapPost)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        let dtos: [ExpressRemoteDTO] = try await apiClient.get(
            "/express/profile/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return dtos.map(ExpressRemoteMapper.mapPost)
    }

    func fetchDetail(postID: String) async throws -> ExpressPostDetail {
        let dto: ExpressRemoteDTO = try await apiClient.get("/express/id/\(postID)", requiresAuth: true)
        return ExpressRemoteMapper.mapDetail(dto)
    }

    func fetchComments(postID: String) async throws -> [ExpressCommentItem] {
        let dtos: [ExpressCommentRemoteDTO] = try await apiClient.get(
            "/express/id/\(postID)/comment",
            requiresAuth: true
        )
        return dtos.map(ExpressRemoteMapper.mapComment)
    }

    func publish(draft: ExpressDraft) async throws {
        let _: EmptyPayload = try await apiClient.postForm(
            "/express",
            fields: ExpressRemoteMapper.formFields(for: draft),
            requiresAuth: true
        )
    }

    func submitComment(postID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/express/id/\(postID)/comment",
            queryItems: [URLQueryItem(name: "comment", value: content)],
            requiresAuth: true
        )
    }

    func like(postID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/express/id/\(postID)/like", requiresAuth: true)
    }

    func guess(postID: String, name: String) async throws -> Bool {
        let result: Bool = try await apiClient.post(
            "/express/id/\(postID)/guess",
            queryItems: [URLQueryItem(name: "name", value: name)],
            requiresAuth: true
        )
        return result
    }
}
