import Foundation

@MainActor
final class MockPhotographRepository: PhotographRepository {
    private var posts: [PhotographPost] = MockPhotographRepository.makeInitialPosts()

    private var comments: [String: [PhotographCommentItem]] = MockPhotographRepository.makeInitialComments()

    private static func makeInitialPosts() -> [PhotographPost] {
        let localeIdentifier = AppLanguage.currentIdentifier()
        return [
            PhotographPost(
                id: "photo_001",
                title: mockLocalizedText(
                    simplifiedChinese: "雨后教学楼",
                    traditionalChinese: "雨後教學樓",
                    english: "Teaching Building After the Rain",
                    japanese: "雨上がりの講義棟",
                    korean: "비 온 뒤의 강의동",
                    localeIdentifier: localeIdentifier
                ),
                contentPreview: mockLocalizedText(
                    simplifiedChinese: "晚课结束后，雨水把教学楼前的树影映得很干净。",
                    traditionalChinese: "晚課結束後，雨水把教學樓前的樹影映得很乾淨。",
                    english: "After the evening class, the rain left the tree shadows in front of the teaching building looking crisp and clear.",
                    japanese: "夜の授業が終わったあと、講義棟前の木の影が雨に映ってとてもきれいでした。",
                    korean: "야간 수업이 끝난 뒤, 강의동 앞 나무 그림자가 빗물에 비쳐 유난히 또렷해 보였어요.",
                    localeIdentifier: localeIdentifier
                ),
                authorName: mockLocalizedText(
                    simplifiedChinese: "校园摄影社",
                    traditionalChinese: "校園攝影社",
                    english: "Campus Photo Club",
                    japanese: "キャンパス写真部",
                    korean: "캠퍼스 사진 동아리",
                    localeIdentifier: localeIdentifier
                ),
                createdAt: mockLocalizedText(
                    simplifiedChinese: "2小时前",
                    traditionalChinese: "2小時前",
                    english: "2 hr ago",
                    japanese: "2時間前",
                    korean: "2시간 전",
                    localeIdentifier: localeIdentifier
                ),
                likeCount: 31,
                commentCount: 8,
                photoCount: 3,
                firstImageURL: "https://example.com/photo/campus-1.jpg",
                isLiked: false,
                category: .campus
            ),
            PhotographPost(
                id: "photo_002",
                title: mockLocalizedText(
                    simplifiedChinese: "操场晚霞",
                    traditionalChinese: "操場晚霞",
                    english: "Sunset Over the Track",
                    japanese: "グラウンドの夕焼け",
                    korean: "운동장 저녁노을",
                    localeIdentifier: localeIdentifier
                ),
                contentPreview: mockLocalizedText(
                    simplifiedChinese: "跑完步抬头就是橙红色的天，今天的心情突然被治愈了。",
                    traditionalChinese: "跑完步抬頭就是橙紅色的天，今天的心情突然被治癒了。",
                    english: "I looked up after my run and saw an orange-red sky. My mood was instantly lifted.",
                    japanese: "走り終わって顔を上げたら空がオレンジ色に染まっていて、一気に気分が軽くなりました。",
                    korean: "달리기를 마치고 올려다본 하늘이 주황빛으로 물들어 있어서 기분이 한순간에 좋아졌어요.",
                    localeIdentifier: localeIdentifier
                ),
                authorName: mockLocalizedText(
                    simplifiedChinese: "周同学",
                    traditionalChinese: "周同學",
                    english: "Zhou",
                    japanese: "周さん",
                    korean: "저우",
                    localeIdentifier: localeIdentifier
                ),
                createdAt: mockLocalizedText(
                    simplifiedChinese: "昨天",
                    traditionalChinese: "昨天",
                    english: "Yesterday",
                    japanese: "昨日",
                    korean: "어제",
                    localeIdentifier: localeIdentifier
                ),
                likeCount: 44,
                commentCount: 12,
                photoCount: 2,
                firstImageURL: "https://example.com/photo/life-1.jpg",
                isLiked: true,
                category: .life
            )
        ]
    }

    private static func makeInitialComments() -> [String: [PhotographCommentItem]] {
        let localeIdentifier = AppLanguage.currentIdentifier()
        return [
            "photo_001": [
                PhotographCommentItem(
                    id: "photo_comment_001",
                    photoID: "photo_001",
                    authorName: mockLocalizedText(
                        simplifiedChinese: "李同学",
                        traditionalChinese: "李同學",
                        english: "Li",
                        japanese: "李さん",
                        korean: "리",
                        localeIdentifier: localeIdentifier
                    ),
                    content: mockLocalizedText(
                        simplifiedChinese: "这张构图很好看。",
                        traditionalChinese: "這張構圖很好看。",
                        english: "The composition in this shot looks great.",
                        japanese: "この構図、とてもいいですね。",
                        korean: "이 사진 구도가 정말 좋아요.",
                        localeIdentifier: localeIdentifier
                    ),
                    createdAt: mockLocalizedText(
                        simplifiedChinese: "20分钟前",
                        traditionalChinese: "20分鐘前",
                        english: "20 min ago",
                        japanese: "20分前",
                        korean: "20분 전",
                        localeIdentifier: localeIdentifier
                    )
                )
            ]
        ]
    }

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
            content: post.contentPreview + "\n\n" + mockLocalizedText(
                simplifiedChinese: "这是一条来自校园摄影模块的详情内容，用于展示文字说明、评论和点赞状态。",
                traditionalChinese: "這是一條來自校園攝影模組的詳情內容，用於展示文字說明、評論和點讚狀態。",
                english: "This is a mock detail entry from the campus photography module, used to show the description, comments, and like status.",
                japanese: "これはキャンパス写真モジュールのモック詳細データで、説明文、コメント、いいね状態を表示するために使われます。",
                korean: "이 내용은 캠퍼스 사진 모듈의 목업 상세 데이터로, 설명, 댓글, 좋아요 상태를 보여주기 위한 것입니다."
            ),
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
                authorName: mockLocalizedText(
                    simplifiedChinese: "我",
                    traditionalChinese: "我",
                    english: "Me",
                    japanese: "私",
                    korean: "나"
                ),
                createdAt: localizedString("common.justNow"),
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
        let comment = PhotographCommentItem(
            id: "photo_comment_\(UUID().uuidString)",
            photoID: postID,
            authorName: mockLocalizedText(
                simplifiedChinese: "我",
                traditionalChinese: "我",
                english: "Me",
                japanese: "私",
                korean: "나"
            ),
            content: content,
            createdAt: localizedString("common.justNow")
        )
        comments[postID, default: []].insert(comment, at: 0)
    }
}
