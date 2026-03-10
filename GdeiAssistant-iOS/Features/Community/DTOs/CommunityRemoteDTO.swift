import Foundation

struct ExpressPostDTO: Decodable {
    let id: Int?
    let username: String?
    let nickname: String?
    let realname: String?
    let selfGender: Int?
    let name: String?
    let content: String?
    let personGender: Int?
    let publishTime: RemoteFlexibleString?
    let likeCount: Int?
    let liked: Bool?
    let commentCount: Int?
    let guessCount: Int?
    let guessSum: Int?
    let canGuess: Bool?
}

struct ExpressCommentDTO: Decodable {
    let id: Int?
    let username: String?
    let nickname: String?
    let expressId: Int?
    let comment: String?
    let publishTime: RemoteFlexibleString?
}

struct TopicPostDTO: Decodable {
    let id: Int?
    let username: String?
    let topic: String?
    let content: String?
    let count: Int?
    let publishTime: RemoteFlexibleString?
    let likeCount: Int?
    let liked: Bool?
    let firstImageUrl: String?
    let imageUrls: [String]?
}
