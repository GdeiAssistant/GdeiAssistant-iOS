import Foundation

enum PhotographCategory: Int, CaseIterable, Identifiable, Codable {
    case campus = 0
    case life = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .campus:
            return "最美校园照"
        case .life:
            return "最美生活照"
        }
    }

    var publishType: Int {
        switch self {
        case .campus:
            return 2
        case .life:
            return 1
        }
    }
}

struct PhotographStats: Codable, Hashable {
    let photoCount: Int
    let commentCount: Int
    let likeCount: Int
}

struct PhotographPost: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let contentPreview: String
    let authorName: String
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
    let photoCount: Int
    let firstImageURL: String?
    let isLiked: Bool
    let category: PhotographCategory
}

struct PhotographPostDetail: Codable, Identifiable, Hashable {
    var id: String { post.id }

    let post: PhotographPost
    let content: String
    let imageURLs: [String]
    let comments: [PhotographCommentItem]
}

struct PhotographCommentItem: Codable, Identifiable, Hashable {
    let id: String
    let photoID: String?
    let authorName: String
    let content: String
    let createdAt: String
}

struct PhotographDraft: Codable {
    let title: String
    let content: String
    let category: PhotographCategory
    let images: [UploadImageAsset]
}
