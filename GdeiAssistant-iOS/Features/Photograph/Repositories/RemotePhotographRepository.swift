import Foundation

@MainActor
final class RemotePhotographRepository: PhotographRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchStats() async throws -> PhotographStats {
        async let photos: Int = apiClient.get("/photograph/statistics/photos", requiresAuth: true)
        async let comments: Int = apiClient.get("/photograph/statistics/comments", requiresAuth: true)
        async let likes: Int = apiClient.get("/photograph/statistics/likes", requiresAuth: true)
        return PhotographStats(photoCount: try await photos, commentCount: try await comments, likeCount: try await likes)
    }

    func fetchPosts(category: PhotographCategory, start: Int, size: Int) async throws -> [PhotographPost] {
        let dtos: [PhotographRemoteDTO] = try await apiClient.get(
            "/photograph/type/\(category.rawValue)/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return dtos.map(PhotographRemoteMapper.mapPost)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [PhotographPost] {
        let dtos: [PhotographRemoteDTO] = try await apiClient.get(
            "/photograph/profile/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return dtos.map(PhotographRemoteMapper.mapPost)
    }

    func fetchDetail(postID: String) async throws -> PhotographPostDetail {
        let dto: PhotographRemoteDTO = try await apiClient.get(
            "/photograph/id/\(postID)",
            requiresAuth: true
        )
        let detail = PhotographRemoteMapper.mapDetail(dto)
        guard detail.imageURLs.isEmpty, detail.post.photoCount > 0 else {
            return detail
        }

        let resolvedImageURLs = try await fetchImageURLs(postID: postID, count: detail.post.photoCount)
        guard !resolvedImageURLs.isEmpty else {
            return detail
        }

        return PhotographPostDetail(
            post: PhotographPost(
                id: detail.post.id,
                title: detail.post.title,
                contentPreview: detail.post.contentPreview,
                authorName: detail.post.authorName,
                createdAt: detail.post.createdAt,
                likeCount: detail.post.likeCount,
                commentCount: detail.post.commentCount,
                photoCount: detail.post.photoCount,
                firstImageURL: detail.post.firstImageURL ?? resolvedImageURLs.first,
                isLiked: detail.post.isLiked,
                category: detail.post.category
            ),
            content: detail.content,
            imageURLs: resolvedImageURLs,
            comments: detail.comments
        )
    }

    func fetchComments(postID: String) async throws -> [PhotographCommentItem] {
        let dtos: [PhotographCommentRemoteDTO] = try await apiClient.get(
            "/photograph/id/\(postID)/comment",
            requiresAuth: true
        )
        return dtos.map(PhotographRemoteMapper.mapComment)
    }

    func publish(draft: PhotographDraft) async throws {
        let fields = [
            FormFieldValue(name: "title", value: draft.title),
            FormFieldValue(name: "content", value: draft.content),
            FormFieldValue(name: "type", value: String(draft.category.publishType))
        ]
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/photograph",
            fields: fields,
            files: PhotographRemoteMapper.files(from: draft),
            requiresAuth: true
        )
    }

    func like(postID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/photograph/id/\(postID)/like",
            requiresAuth: true
        )
    }

    func submitComment(postID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/photograph/id/\(postID)/comment",
            queryItems: [URLQueryItem(name: "comment", value: content)],
            requiresAuth: true
        )
    }

    private func fetchImageURLs(postID: String, count: Int) async throws -> [String] {
        guard count > 0 else { return [] }

        var urls = [String]()
        for index in 1...count {
            let imageURL: String = try await apiClient.get(
                "/photograph/id/\(postID)/index/\(index)/image",
                requiresAuth: true
            )
            if let sanitized = RemoteMapperSupport.sanitizedText(imageURL) {
                urls.append(sanitized)
            }
        }
        return urls
    }
}
