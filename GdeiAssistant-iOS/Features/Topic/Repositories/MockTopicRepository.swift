import Foundation

@MainActor
final class MockTopicRepository: TopicRepository {
    private var posts: [TopicPost] = [
        TopicPost(
            id: "topic_001",
            topic: "SwiftUI",
            contentPreview: "这周社团分享会准备讲 SwiftUI 工程拆分，有没有同学想一起交流导航和 Repository 设计？",
            authorName: "iOS 开发社",
            publishedAt: "15分钟前",
            likeCount: 26,
            imageCount: 1,
            firstImageURL: "https://example.com/topic/swiftui.jpg",
            isLiked: false
        ),
        TopicPost(
            id: "topic_002",
            topic: "考证",
            contentPreview: "准备四月冲软考中级，想找几个一起打卡刷题的同学，周末可以线下自习。",
            authorName: "陈同学",
            publishedAt: "1小时前",
            likeCount: 19,
            imageCount: 0,
            firstImageURL: nil,
            isLiked: true
        ),
        TopicPost(
            id: "topic_003",
            topic: "图书馆",
            contentPreview: "图书馆五楼新开了夜间讨论区，插座和灯光都比以前好很多，适合做课程展示排练。",
            authorName: "学习互助站",
            publishedAt: "昨天",
            likeCount: 42,
            imageCount: 2,
            firstImageURL: "https://example.com/topic/library.jpg",
            isLiked: false
        )
    ]

    private var detailContents: [String: String] = [
        "topic_001": "#SwiftUI\n\n这周社团分享会准备讲 SwiftUI 工程拆分，有没有同学想一起交流导航和 Repository 设计？\n\n计划重点聊路由分发、Repository 切换、Preview 数据隔离。",
        "topic_002": "#考证\n\n准备四月冲软考中级，想找几个一起打卡刷题的同学，周末可以线下自习。\n\n如果你最近也在做题，可以一起整理错题本。",
        "topic_003": "#图书馆\n\n图书馆五楼新开了夜间讨论区，插座和灯光都比以前好很多，适合做课程展示排练。\n\n晚上九点后人会少一点，适合小组讨论。"
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
            authorName: "我",
            publishedAt: "刚刚",
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
