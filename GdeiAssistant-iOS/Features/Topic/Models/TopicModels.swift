import Foundation

struct TopicPost: Codable, Identifiable, Hashable {
    let id: String
    let topic: String
    let contentPreview: String
    let authorName: String
    let publishedAt: String
    let likeCount: Int
    let imageCount: Int
    let firstImageURL: String?
    let isLiked: Bool
}

struct TopicPostDetail: Codable, Identifiable, Hashable {
    var id: String { post.id }

    let post: TopicPost
    let content: String
    let imageURLs: [String]
}

struct TopicDraft: Codable {
    let topic: String
    let content: String
    let images: [UploadImageAsset]
}
