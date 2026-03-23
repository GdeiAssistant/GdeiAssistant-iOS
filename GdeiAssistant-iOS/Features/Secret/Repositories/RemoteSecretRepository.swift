import Foundation

@MainActor
final class RemoteSecretRepository: SecretRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPosts() async throws -> [SecretPost] {
        let dtos: [SecretPostDTO] = try await apiClient.get("/secret/info/start/0/size/20", requiresAuth: true)
        return SecretRemoteMapper.mapPosts(dtos)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [SecretPost] {
        let dtos: [SecretPostDTO] = try await apiClient.get("/secret/profile/start/\(start)/size/\(size)", requiresAuth: true)
        return SecretRemoteMapper.mapPosts(dtos)
    }

    func fetchDetail(postID: String) async throws -> SecretPostDetail {
        let detailDTO: SecretPostDTO = try await apiClient.get("/secret/id/\(postID)", requiresAuth: true)
        let comments: [SecretCommentDTO] = (try? await apiClient.get("/secret/id/\(postID)/comments", requiresAuth: true)) ?? []
        return SecretRemoteMapper.mapDetail(detailDTO, comments: comments.isEmpty ? detailDTO.secretCommentList ?? [] : comments)
    }

    func publish(draft: SecretDraft) async throws {
        let dto = SecretRemoteMapper.mapPublishDTO(draft)
        let fields = SecretRemoteMapper.mapPublishFields(dto)
        switch draft.mode {
        case .text:
            let _: EmptyPayload = try await apiClient.postForm(
                "/secret/info",
                fields: fields,
                requiresAuth: true
            )
        case .voice:
            guard let voice = draft.voice else {
                throw NetworkError.server(code: 400, message: "语音内容不能为空")
            }
            let _: EmptyPayload = try await apiClient.postMultipart(
                "/secret/info",
                fields: fields,
                files: [
                    MultipartFormFile(
                        name: "voice",
                        fileName: voice.fileName,
                        mimeType: voice.mimeType,
                        data: voice.fileData
                    )
                ],
                requiresAuth: true
            )
        }
    }

    func submitComment(postID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/secret/id/\(postID)/comment",
            queryItems: [URLQueryItem(name: "comment", value: content)],
            requiresAuth: true
        )
    }

    func setLike(postID: String, liked: Bool) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/secret/id/\(postID)/like",
            queryItems: [URLQueryItem(name: "like", value: liked ? "1" : "0")],
            requiresAuth: true
        )
    }
}
