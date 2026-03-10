import Foundation

@MainActor
final class RemoteTopicRepository: TopicRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPosts(start: Int, size: Int) async throws -> [TopicPost] {
        let dtos: [TopicRemoteDTO] = try await apiClient.get(
            "/topic/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return try await mapPostsResolvingImages(dtos)
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [TopicPost] {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? keyword
        let dtos: [TopicRemoteDTO] = try await apiClient.get(
            "/topic/keyword/\(encodedKeyword)/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return try await mapPostsResolvingImages(dtos)
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [TopicPost] {
        let dtos: [TopicRemoteDTO] = try await apiClient.get(
            "/topic/profile/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: true
        )
        return try await mapPostsResolvingImages(dtos)
    }

    func fetchDetail(postID: String) async throws -> TopicPostDetail {
        let dto: TopicRemoteDTO = try await apiClient.get("/topic/id/\(postID)", requiresAuth: true)
        let detail = TopicRemoteMapper.mapDetail(dto)
        guard detail.imageURLs.isEmpty, detail.post.imageCount > 0 else {
            return detail
        }

        let resolvedImageURLs = try await fetchImageURLs(postID: postID, count: detail.post.imageCount)
        guard !resolvedImageURLs.isEmpty else {
            return detail
        }

        return TopicPostDetail(
            post: TopicPost(
                id: detail.post.id,
                topic: detail.post.topic,
                contentPreview: detail.post.contentPreview,
                authorName: detail.post.authorName,
                publishedAt: detail.post.publishedAt,
                likeCount: detail.post.likeCount,
                imageCount: detail.post.imageCount,
                firstImageURL: detail.post.firstImageURL ?? resolvedImageURLs.first,
                isLiked: detail.post.isLiked
            ),
            content: detail.content,
            imageURLs: resolvedImageURLs
        )
    }

    func publish(draft: TopicDraft) async throws {
        let fields = [
            FormFieldValue(name: "topic", value: draft.topic),
            FormFieldValue(name: "content", value: draft.content),
            FormFieldValue(name: "count", value: String(draft.images.count))
        ]
        let files = TopicRemoteMapper.multipartFiles(from: draft.images)
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/topic",
            fields: fields,
            files: files,
            requiresAuth: true
        )
    }

    func like(postID: String) async throws {
        let _: EmptyPayload = try await apiClient.post("/topic/id/\(postID)/like", requiresAuth: true)
    }

    private func mapPostsResolvingImages(_ dtos: [TopicRemoteDTO]) async throws -> [TopicPost] {
        var posts = [TopicPost]()
        posts.reserveCapacity(dtos.count)

        for dto in dtos {
            let post = TopicRemoteMapper.mapPost(dto)
            guard post.firstImageURL == nil, post.imageCount > 0 else {
                posts.append(post)
                continue
            }

            let resolvedFirstImage = try? await fetchImageURL(postID: post.id, index: 1)
            posts.append(
                TopicPost(
                    id: post.id,
                    topic: post.topic,
                    contentPreview: post.contentPreview,
                    authorName: post.authorName,
                    publishedAt: post.publishedAt,
                    likeCount: post.likeCount,
                    imageCount: post.imageCount,
                    firstImageURL: resolvedFirstImage ?? post.firstImageURL,
                    isLiked: post.isLiked
                )
            )
        }

        return posts
    }

    private func fetchImageURLs(postID: String, count: Int) async throws -> [String] {
        guard count > 0 else { return [] }

        var urls = [String]()
        for index in 1...count {
            if let url = try? await fetchImageURL(postID: postID, index: index) {
                urls.append(url)
            }
        }
        return urls
    }

    private func fetchImageURL(postID: String, index: Int) async throws -> String? {
        let imageURL: String = try await apiClient.get("/topic/id/\(postID)/index/\(index)/image", requiresAuth: true)
        return RemoteMapperSupport.sanitizedText(imageURL)
    }
}
