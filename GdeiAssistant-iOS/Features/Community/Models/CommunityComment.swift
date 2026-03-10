import Foundation

struct CommunityComment: Codable, Identifiable, Hashable {
    let id: String
    let authorName: String
    let isAnonymous: Bool
    let createdAt: String
    let content: String
    let likeCount: Int
}
