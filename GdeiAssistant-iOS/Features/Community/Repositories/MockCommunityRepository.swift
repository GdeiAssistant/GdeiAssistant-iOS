import Foundation

@MainActor
final class MockCommunityRepository: CommunityRepository {
    private var hotPosts = MockSeedData.communityHotPosts
    private var latestPosts = MockSeedData.communityLatestPosts
    private var commentsByPostID = MockSeedData.communityCommentsByPostID
    private var likedPostIDs: Set<String> = []

    func fetchPosts(sort: CommunityFeedSort) async throws -> [CommunityPost] {
        try await Task.sleep(nanoseconds: 350_000_000)
        switch sort {
        case .hot:
            return hotPosts
        case .latest:
            return latestPosts
        }
    }

    func fetchPostDetail(postID: String) async throws -> CommunityPostDetail {
        try await Task.sleep(nanoseconds: 180_000_000)

        guard let post = findPost(postID: postID) else {
            throw NetworkError.server(code: 404, message: "帖子不存在或已被删除")
        }

        return CommunityPostDetail(
            post: post,
            content: MockFactory.makeCommunityPostContent(postID: postID),
            topics: post.tags.map { MockFactory.makeCommunityTopic(topicID: $0) },
            isLiked: likedPostIDs.contains(postID)
        )
    }

    func fetchComments(postID: String) async throws -> [CommunityComment] {
        try await Task.sleep(nanoseconds: 160_000_000)
        return commentsByPostID[postID] ?? []
    }

    func submitComment(postID: String, content: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw NetworkError.server(code: 400, message: "评论内容不能为空")
        }

        let newComment = CommunityComment(
            id: "comment_\(UUID().uuidString)",
            authorName: MockSeedData.demoProfile.nickname,
            isAnonymous: false,
            createdAt: "刚刚",
            content: trimmedContent,
            likeCount: 0
        )

        var comments = commentsByPostID[postID] ?? []
        comments.insert(newComment, at: 0)
        commentsByPostID[postID] = comments
        updatePost(postID: postID) { post in
            post.updating(commentCount: comments.count)
        }
    }

    func toggleLike(postID: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)

        if likedPostIDs.contains(postID) {
            likedPostIDs.remove(postID)
            updatePost(postID: postID) { post in
                post.updating(likeCount: max(0, post.likeCount - 1))
            }
        } else {
            likedPostIDs.insert(postID)
            updatePost(postID: postID) { post in
                post.updating(likeCount: post.likeCount + 1)
            }
        }
    }

    func fetchTopic(topicID: String) async throws -> CommunityTopic {
        try await Task.sleep(nanoseconds: 120_000_000)
        return MockFactory.makeCommunityTopic(topicID: topicID)
    }

    func fetchTopicPosts(topicID: String, sort: CommunityFeedSort) async throws -> [CommunityPost] {
        try await Task.sleep(nanoseconds: 200_000_000)

        let sourcePosts: [CommunityPost]
        switch sort {
        case .hot:
            sourcePosts = hotPosts
        case .latest:
            sourcePosts = latestPosts
        }

        return sourcePosts.filter { $0.tags.contains(topicID) }
    }

    private func findPost(postID: String) -> CommunityPost? {
        hotPosts.first(where: { $0.id == postID }) ?? latestPosts.first(where: { $0.id == postID })
    }

    private func updatePost(postID: String, transform: (CommunityPost) -> CommunityPost) {
        if let index = hotPosts.firstIndex(where: { $0.id == postID }) {
            hotPosts[index] = transform(hotPosts[index])
        }

        if let index = latestPosts.firstIndex(where: { $0.id == postID }) {
            latestPosts[index] = transform(latestPosts[index])
        }
    }
}
