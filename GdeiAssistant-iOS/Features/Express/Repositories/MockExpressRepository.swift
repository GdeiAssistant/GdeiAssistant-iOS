import Foundation

@MainActor
final class MockExpressRepository: ExpressRepository {
    private var posts: [ExpressPost] = [
        ExpressPost(
            id: "express_001",
            nickname: localizedString("mock.express.post1.nickname"),
            targetName: localizedString("mock.express.post1.targetName"),
            contentPreview: localizedString("mock.express.post1.contentPreview"),
            publishTime: localizedString("mock.express.post1.publishTime"),
            likeCount: 68,
            commentCount: 14,
            guessCount: 21,
            correctGuessCount: 3,
            isLiked: false,
            canGuess: true,
            selfGender: .female,
            targetGender: .male
        ),
        ExpressPost(
            id: "express_002",
            nickname: localizedString("mock.express.post2.nickname"),
            targetName: localizedString("mock.express.post2.targetName"),
            contentPreview: localizedString("mock.express.post2.contentPreview"),
            publishTime: localizedString("mock.express.post2.publishTime"),
            likeCount: 41,
            commentCount: 9,
            guessCount: 12,
            correctGuessCount: 1,
            isLiked: true,
            canGuess: false,
            selfGender: .male,
            targetGender: .female
        )
    ]

    private var comments: [String: [ExpressCommentItem]] = [
        "express_001": [
            ExpressCommentItem(id: "express_comment_001", authorName: localizedString("mock.express.comment1.authorName"), content: localizedString("mock.express.comment1.content"), publishTime: localizedString("mock.express.comment1.publishTime"))
        ]
    ]

    func fetchPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        Array(posts.dropFirst(start).prefix(size))
    }

    func searchPosts(keyword: String, start: Int, size: Int) async throws -> [ExpressPost] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = posts.filter {
            trimmedKeyword.isEmpty ||
            $0.nickname.localizedCaseInsensitiveContains(trimmedKeyword) ||
            $0.targetName.localizedCaseInsensitiveContains(trimmedKeyword) ||
            $0.contentPreview.localizedCaseInsensitiveContains(trimmedKeyword)
        }
        return Array(filtered.dropFirst(start).prefix(size))
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [ExpressPost] {
        Array(posts.prefix(1).dropFirst(start).prefix(size))
    }

    func fetchDetail(postID: String) async throws -> ExpressPostDetail {
        let post = posts.first(where: { $0.id == postID }) ?? posts[0]
        return ExpressPostDetail(
            post: post,
            realName: post.canGuess ? localizedString("mock.express.detail.realName") : nil,
            content: post.contentPreview + "\n\n" + localizedString("mock.express.detail.contentSuffix")
        )
    }

    func fetchComments(postID: String) async throws -> [ExpressCommentItem] {
        comments[postID] ?? []
    }

    func publish(draft: ExpressDraft) async throws {
        let post = ExpressPost(
            id: "express_mock_\(UUID().uuidString)",
            nickname: draft.nickname,
            targetName: draft.targetName,
            contentPreview: RemoteMapperSupport.truncated(draft.content, limit: 72),
            publishTime: localizedString("mock.express.justNow"),
            likeCount: 0,
            commentCount: 0,
            guessCount: 0,
            correctGuessCount: 0,
            isLiked: false,
            canGuess: !(draft.realName ?? "").isEmpty,
            selfGender: draft.selfGender,
            targetGender: draft.targetGender
        )
        posts.insert(post, at: 0)
    }

    func submitComment(postID: String, content: String) async throws {
        let item = ExpressCommentItem(
            id: "express_comment_\(UUID().uuidString)",
            authorName: localizedString("mock.express.commentAuthorMe"),
            content: content,
            publishTime: localizedString("mock.express.justNow")
        )
        comments[postID, default: []].insert(item, at: 0)
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let post = posts[index]
            posts[index] = ExpressPost(
                id: post.id,
                nickname: post.nickname,
                targetName: post.targetName,
                contentPreview: post.contentPreview,
                publishTime: post.publishTime,
                likeCount: post.likeCount,
                commentCount: post.commentCount + 1,
                guessCount: post.guessCount,
                correctGuessCount: post.correctGuessCount,
                isLiked: post.isLiked,
                canGuess: post.canGuess,
                selfGender: post.selfGender,
                targetGender: post.targetGender
            )
        }
    }

    func like(postID: String) async throws {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let post = posts[index]
        posts[index] = ExpressPost(
            id: post.id,
            nickname: post.nickname,
            targetName: post.targetName,
            contentPreview: post.contentPreview,
            publishTime: post.publishTime,
            likeCount: post.likeCount + (post.isLiked ? 0 : 1),
            commentCount: post.commentCount,
            guessCount: post.guessCount,
            correctGuessCount: post.correctGuessCount,
            isLiked: true,
            canGuess: post.canGuess,
            selfGender: post.selfGender,
            targetGender: post.targetGender
        )
    }

    func guess(postID: String, name: String) async throws -> Bool {
        let matched = name.trimmingCharacters(in: .whitespacesAndNewlines) == localizedString("mock.express.detail.realName")
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let post = posts[index]
            posts[index] = ExpressPost(
                id: post.id,
                nickname: post.nickname,
                targetName: post.targetName,
                contentPreview: post.contentPreview,
                publishTime: post.publishTime,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                guessCount: post.guessCount + 1,
                correctGuessCount: post.correctGuessCount + (matched ? 1 : 0),
                isLiked: post.isLiked,
                canGuess: post.canGuess,
                selfGender: post.selfGender,
                targetGender: post.targetGender
            )
        }
        return matched
    }
}
