import Foundation

@MainActor
final class MockPhotographRepository: PhotographRepository {
    private var posts: [PhotographPost] = [
        PhotographPost(id: "photo_001", title: "雨后教学楼", contentPreview: "晚课结束后，雨水把教学楼前的树影映得很干净。", authorName: "校园摄影社", createdAt: "2小时前", likeCount: 31, commentCount: 8, photoCount: 3, firstImageURL: "https://example.com/photo/campus-1.jpg", isLiked: false, category: .campus),
        PhotographPost(id: "photo_002", title: "操场晚霞", contentPreview: "跑完步抬头就是橙红色的天，今天的心情突然被治愈了。", authorName: "周同学", createdAt: "昨天", likeCount: 44, commentCount: 12, photoCount: 2, firstImageURL: "https://example.com/photo/life-1.jpg", isLiked: true, category: .life)
    ]

    private var comments: [String: [PhotographCommentItem]] = [
        "photo_001": [PhotographCommentItem(id: "photo_comment_001", photoID: "photo_001", authorName: "李同学", content: "这张构图很好看。", createdAt: "20分钟前")]
    ]

    func fetchStats() async throws -> PhotographStats {
        PhotographStats(photoCount: 128, commentCount: 462, likeCount: 1034)
    }

    func fetchPosts(category: PhotographCategory, start: Int, size: Int) async throws -> [PhotographPost] {
        let filtered = posts.filter { $0.category == category }
        return Array(filtered.dropFirst(start).prefix(size))
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [PhotographPost] {
        Array(posts.prefix(1).dropFirst(start).prefix(size))
    }

    func fetchDetail(postID: String) async throws -> PhotographPostDetail {
        let post = posts.first(where: { $0.id == postID }) ?? posts[0]
        return PhotographPostDetail(
            post: post,
            content: post.contentPreview + "\n\n这是一条来自校园摄影模块的详情内容，用于展示文字说明、评论和点赞状态。",
            imageURLs: (0..<max(post.photoCount, 1)).map { _ in post.firstImageURL ?? "https://example.com/photo/default.jpg" },
            comments: comments[postID] ?? []
        )
    }

    func fetchComments(postID: String) async throws -> [PhotographCommentItem] {
        comments[postID] ?? []
    }

    func publish(draft: PhotographDraft) async throws {
        posts.insert(
            PhotographPost(
                id: "photo_mock_\(UUID().uuidString)",
                title: draft.title,
                contentPreview: RemoteMapperSupport.truncated(draft.content, limit: 60),
                authorName: "我",
                createdAt: "刚刚",
                likeCount: 0,
                commentCount: 0,
                photoCount: draft.images.count,
                firstImageURL: draft.images.isEmpty ? nil : "mock://photo/0",
                isLiked: false,
                category: draft.category
            ),
            at: 0
        )
    }

    func like(postID: String) async throws {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let post = posts[index]
        posts[index] = PhotographPost(
            id: post.id,
            title: post.title,
            contentPreview: post.contentPreview,
            authorName: post.authorName,
            createdAt: post.createdAt,
            likeCount: post.likeCount + (post.isLiked ? 0 : 1),
            commentCount: post.commentCount,
            photoCount: post.photoCount,
            firstImageURL: post.firstImageURL,
            isLiked: true,
            category: post.category
        )
    }

    func submitComment(postID: String, content: String) async throws {
        let comment = PhotographCommentItem(id: "photo_comment_\(UUID().uuidString)", photoID: postID, authorName: "我", content: content, createdAt: "刚刚")
        comments[postID, default: []].insert(comment, at: 0)
    }
}
