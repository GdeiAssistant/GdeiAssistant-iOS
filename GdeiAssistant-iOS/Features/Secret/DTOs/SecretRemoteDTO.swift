import Foundation

struct SecretCommentDTO: Decodable {
    let id: Int?
    let contentId: Int?
    let username: String?
    let comment: String?
    let publishTime: RemoteFlexibleString?
    let avatarTheme: Int?
}

struct SecretPostDTO: Decodable {
    let id: Int?
    let username: String?
    let content: String?
    let theme: Int?
    let type: Int?
    let timer: Int?
    let state: Int?
    let publishTime: RemoteFlexibleString?
    let likeCount: Int?
    let commentCount: Int?
    let liked: Int?
    let voiceURL: String?
    let secretCommentList: [SecretCommentDTO]?
}

struct SecretPublishRemoteDTO: Codable {
    let theme: Int
    let content: String?
    let type: Int
    let timer: Int
}
