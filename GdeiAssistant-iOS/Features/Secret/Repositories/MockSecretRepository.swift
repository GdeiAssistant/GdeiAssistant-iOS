import Foundation

@MainActor
final class MockSecretRepository: SecretRepository {
    private var posts = MockFactory.makeSecretPosts()
    private var detailsByID = MockFactory.makeSecretDetailsByID()

    func fetchPosts() async throws -> [SecretPost] {
        try await Task.sleep(nanoseconds: 220_000_000)
        return posts
    }

    func fetchMyPosts(start: Int, size: Int) async throws -> [SecretPost] {
        try await Task.sleep(nanoseconds: 120_000_000)
        let end = min(start + size, posts.count)
        guard start < posts.count else { return [] }
        return Array(posts[start..<end])
    }

    func fetchDetail(postID: String) async throws -> SecretPostDetail {
        try await Task.sleep(nanoseconds: 160_000_000)

        guard let detail = detailsByID[postID] else {
            throw NetworkError.server(code: 404, message: localizedString("secret.notFound"))
        }

        return detail
    }

    func publish(draft: SecretDraft) async throws {
        try await Task.sleep(nanoseconds: 220_000_000)

        let postID = "secret_\(UUID().uuidString)"
        let post = SecretPost(
            id: postID,
            username: MockSeedData.demoProfile.username,
            themeID: draft.themeID,
            title: draft.title,
            summary: draft.mode == .text
                ? String((draft.content ?? "").prefix(44))
                : mockLocalizedText(
                    simplifiedChinese: "点击进入详情播放语音内容",
                    traditionalChinese: "點擊進入詳情播放語音內容",
                    english: "Open details to play the voice post",
                    japanese: "詳細を開いて音声を再生",
                    korean: "상세 화면에서 음성 재생"
                ),
            createdAt: draft.timerEnabled
                ? mockLocalizedText(
                    simplifiedChinese: "刚刚 · 24 小时后自动删除",
                    traditionalChinese: "剛剛 · 24 小時後自動刪除",
                    english: "Just now · Auto-delete in 24 hours",
                    japanese: "たった今 ・ 24時間後に自動削除",
                    korean: "방금 전 · 24시간 후 자동 삭제"
                )
                : mockLocalizedText(
                    simplifiedChinese: "刚刚",
                    traditionalChinese: "剛剛",
                    english: "Just now",
                    japanese: "たった今",
                    korean: "방금 전"
                ),
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            type: draft.mode.rawValue,
            timer: draft.timerEnabled ? 1 : 0,
            state: 0,
            voiceURL: draft.mode == .voice ? MockSeedData.secretVoiceURL : nil
        )

        posts.insert(post, at: 0)
        detailsByID[postID] = SecretPostDetail(
            post: post,
            content: draft.content ?? mockLocalizedText(
                simplifiedChinese: "这是一条新发布的语音树洞，点击播放即可试听。",
                traditionalChinese: "這是一條新發布的語音樹洞，點擊播放即可試聽。",
                english: "This is a newly posted voice secret. Tap play to preview it.",
                japanese: "新しく投稿された音声ツリーです。再生をタップすると試聴できます。",
                korean: "새로 올라온 음성 트리홀입니다. 재생을 눌러 들어볼 수 있어요."
            ),
            comments: []
        )
    }

    func submitComment(postID: String, content: String) async throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw NetworkError.server(code: 400, message: localizedString("secret.commentEmpty"))
        }
        guard trimmedContent.count <= 50 else {
            throw NetworkError.server(code: 400, message: localizedString("secret.commentTooLong"))
        }
        guard let detail = detailsByID[postID] else {
            throw NetworkError.server(code: 404, message: localizedString("secret.notFound"))
        }

        let comment = SecretComment(
            id: "secret_comment_\(UUID().uuidString)",
            authorName: MockSeedData.demoProfile.nickname,
            content: trimmedContent,
            createdAt: mockLocalizedText(
                simplifiedChinese: "刚刚",
                traditionalChinese: "剛剛",
                english: "Just now",
                japanese: "たった今",
                korean: "방금 전"
            ),
            avatarTheme: 1
        )
        let updatedComments = [comment] + detail.comments
        let updatedPost = SecretPost(
            id: detail.post.id,
            username: detail.post.username,
            themeID: detail.post.themeID,
            title: detail.post.title,
            summary: detail.post.summary,
            createdAt: detail.post.createdAt,
            likeCount: detail.post.likeCount,
            commentCount: updatedComments.count,
            isLiked: detail.post.isLiked,
            type: detail.post.type,
            timer: detail.post.timer,
            state: detail.post.state,
            voiceURL: detail.post.voiceURL
        )
        detailsByID[postID] = SecretPostDetail(post: updatedPost, content: detail.content, comments: updatedComments)
        syncPost(updatedPost)
    }

    func setLike(postID: String, liked: Bool) async throws {
        guard let detail = detailsByID[postID] else {
            throw NetworkError.server(code: 404, message: localizedString("secret.notFound"))
        }

        let updatedPost = SecretPost(
            id: detail.post.id,
            username: detail.post.username,
            themeID: detail.post.themeID,
            title: detail.post.title,
            summary: detail.post.summary,
            createdAt: detail.post.createdAt,
            likeCount: max(0, detail.post.likeCount + (liked ? 1 : -1)),
            commentCount: detail.post.commentCount,
            isLiked: liked,
            type: detail.post.type,
            timer: detail.post.timer,
            state: detail.post.state,
            voiceURL: detail.post.voiceURL
        )
        detailsByID[postID] = SecretPostDetail(post: updatedPost, content: detail.content, comments: detail.comments)
        syncPost(updatedPost)
    }

    private func syncPost(_ post: SecretPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        }
    }
}
