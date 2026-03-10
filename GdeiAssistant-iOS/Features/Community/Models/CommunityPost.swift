import Foundation

struct CommunityPost: Codable, Identifiable, Hashable {
    let id: String
    let authorName: String
    let authorAvatarURL: String
    let isAnonymous: Bool
    let createdAt: String
    let title: String
    let summary: String
    let tags: [String]
    let likeCount: Int
    let commentCount: Int

    func updating(
        likeCount: Int? = nil,
        commentCount: Int? = nil
    ) -> CommunityPost {
        CommunityPost(
            id: id,
            authorName: authorName,
            authorAvatarURL: authorAvatarURL,
            isAnonymous: isAnonymous,
            createdAt: createdAt,
            title: title,
            summary: summary,
            tags: tags,
            likeCount: likeCount ?? self.likeCount,
            commentCount: commentCount ?? self.commentCount
        )
    }
}

struct CommunityPostDetail: Codable, Identifiable, Hashable {
    var id: String { post.id }

    let post: CommunityPost
    let content: String
    let topics: [CommunityTopic]
    let isLiked: Bool

    func updating(
        post: CommunityPost? = nil,
        isLiked: Bool? = nil
    ) -> CommunityPostDetail {
        CommunityPostDetail(
            post: post ?? self.post,
            content: content,
            topics: topics,
            isLiked: isLiked ?? self.isLiked
        )
    }
}
