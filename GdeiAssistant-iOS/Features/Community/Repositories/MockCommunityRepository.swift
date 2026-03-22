import Foundation

@MainActor
final class MockCommunityRepository: CommunityRepository {
    private var likeCountOverrides: [String: Int] = [:]
    private var commentCountOverrides: [String: Int] = [:]
    private var addedComments: [String: [CommunityComment]] = [:]
    private var likedPostIDs: Set<String> = []

    private func hotPosts() -> [CommunityPost] {
        MockSeedData.communityHotPosts.map { applyOverrides($0) }
    }

    private func latestPosts() -> [CommunityPost] {
        MockSeedData.communityLatestPosts.map { applyOverrides($0) }
    }

    private func comments(for postID: String) -> [CommunityComment] {
        let seedComments = MockSeedData.communityCommentsByPostID[postID] ?? []
        let added = addedComments[postID] ?? []
        return added + seedComments
    }

    private func applyOverrides(_ post: CommunityPost) -> CommunityPost {
        var result = post
        if let likeCount = likeCountOverrides[post.id] {
            result = result.updating(likeCount: likeCount)
        }
        if let commentCount = commentCountOverrides[post.id] {
            result = result.updating(commentCount: commentCount)
        }
        return result
    }

    func fetchPosts(sort: CommunityFeedSort) async throws -> [CommunityPost] {
        try await Task.sleep(nanoseconds: 350_000_000)
        switch sort {
        case .hot:
            return hotPosts()
        case .latest:
            return latestPosts()
        }
    }

    func fetchPostDetail(postID: String) async throws -> CommunityPostDetail {
        try await Task.sleep(nanoseconds: 180_000_000)

        guard let post = findPost(postID: postID) else {
            throw NetworkError.server(code: 404, message: localizedString("mock.community.postNotFound"))
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
        return comments(for: postID)
    }

    func submitComment(postID: String, content: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw NetworkError.server(code: 400, message: localizedString("mock.community.emptyComment"))
        }

        let newComment = CommunityComment(
            id: "comment_\(UUID().uuidString)",
            authorName: MockSeedData.demoProfile.nickname,
            isAnonymous: false,
            createdAt: localizedString("mock.community.justNow"),
            content: trimmedContent,
            likeCount: 0
        )

        var added = addedComments[postID] ?? []
        added.insert(newComment, at: 0)
        addedComments[postID] = added

        let totalComments = comments(for: postID).count
        commentCountOverrides[postID] = totalComments
    }

    func toggleLike(postID: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)

        let currentCount = likeCountOverrides[postID] ?? findPost(postID: postID)?.likeCount ?? 0

        if likedPostIDs.contains(postID) {
            likedPostIDs.remove(postID)
            likeCountOverrides[postID] = max(0, currentCount - 1)
        } else {
            likedPostIDs.insert(postID)
            likeCountOverrides[postID] = currentCount + 1
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
            sourcePosts = hotPosts()
        case .latest:
            sourcePosts = latestPosts()
        }

        return sourcePosts.filter { $0.tags.contains(topicID) }
    }

    private func findPost(postID: String) -> CommunityPost? {
        let post = hotPosts().first(where: { $0.id == postID }) ?? latestPosts().first(where: { $0.id == postID })
        return post
    }
}
