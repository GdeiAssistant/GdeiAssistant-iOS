import Foundation

@MainActor
final class MockTopicRepository: TopicRepository {
    private var posts: [TopicPost] = [
        TopicPost(
            id: "topic_001",
            topic: localizedString("mock.topic.post1Topic"),
            contentPreview: localizedString("mock.topic.post1Preview"),
            authorName: localizedString("mock.topic.post1Author"),
            publishedAt: localizedString("mock.topic.post1Time"),
            likeCount: 26,
            imageCount: 1,
            firstImageURL: "https://example.com/topic/swiftui.jpg",
            isLiked: false
        ),
        TopicPost(
            id: "topic_002",
            topic: localizedString("mock.topic.post2Topic"),
            contentPreview: localizedString("mock.topic.post2Preview"),
            authorName: localizedString("mock.topic.post2Author"),
            publishedAt: localizedString("mock.topic.post2Time"),
            likeCount: 19,
            imageCount: 0,
            firstImageURL: nil,
            isLiked: true
        ),
        TopicPost(
            id: "topic_003",
            topic: localizedString("mock.topic.post3Topic"),
            contentPreview: localizedString("mock.topic.post3Preview"),
            authorName: localizedString("mock.topic.post3Author"),
            publishedAt: localizedString("mock.topic.post3Time"),
            likeCount: 42,
            imageCount: 2,
            firstImageURL: "https://example.com/topic/library.jpg",
            isLiked: false
        )
    ]

    private var detailContents: [String: String] = [
        "topic_001": localizedString("mock.topic.post1Detail"),
        "topic_002": localizedString("mock.topic.post2Detail"),
        "topic_003": localizedString("mock.topic.post3Detail")
    ]

    func fetchPosts(start: Int, size: Int) async throws -> [TopicPost] {
        Array(posts.dropFirst(start).prefix(size))
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [TopicPost] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = posts.filter {
            trimmedKeyword.isEmpty ||
            $0.topic.localizedCaseInsensitiveContains(trimmedKeyword) ||
            ($0.contentPreview + (detailContents[$0.id] ?? "")).localizedCaseInsensitiveContains(trimmedKeyword) ||
            $0.authorName.localizedCaseInsensitiveContains(trimmedKeyword)
        }
        return Array(filtered.dropFirst(start).prefix(size))
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [TopicPost] {
        Array(posts.prefix(2).dropFirst(start).prefix(size))
    }

    func fetchDetail(postID: String) async throws -> TopicPostDetail {
        let post = try findPost(postID: postID)
        let images = post.imageCount > 0 ? (0..<post.imageCount).map { _ in
            post.firstImageURL ?? "https://example.com/topic/default.jpg"
        } : []
        return TopicPostDetail(
            post: post,
            content: detailContents[postID] ?? post.contentPreview,
            imageURLs: images
        )
    }

    func publish(draft: TopicDraft) async throws {
        let newID = "topic_mock_\(UUID().uuidString)"
        let preview = RemoteMapperSupport.truncated(draft.content, limit: 64)
        let newPost = TopicPost(
            id: newID,
            topic: draft.topic,
            contentPreview: preview,
            authorName: localizedString("mock.topic.me"),
            publishedAt: localizedString("mock.topic.justNow"),
            likeCount: 0,
            imageCount: draft.images.count,
            firstImageURL: draft.images.isEmpty ? nil : "mock://topic/image/0",
            isLiked: false
        )
        posts.insert(newPost, at: 0)
        detailContents[newID] = "#\(draft.topic)\n\n\(draft.content)"
    }

    func like(postID: String) async throws {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let post = posts[index]
        posts[index] = TopicPost(
            id: post.id,
            topic: post.topic,
            contentPreview: post.contentPreview,
            authorName: post.authorName,
            publishedAt: post.publishedAt,
            likeCount: post.likeCount + (post.isLiked ? 0 : 1),
            imageCount: post.imageCount,
            firstImageURL: post.firstImageURL,
            isLiked: true
        )
    }

    private func findPost(postID: String) throws -> TopicPost {
        guard let post = posts.first(where: { $0.id == postID }) else {
            throw NetworkError.noData
        }
        return post
    }
}
