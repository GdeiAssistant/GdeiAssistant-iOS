import Foundation

struct ExpressRemoteDTO: Decodable {
    let id: RemoteFlexibleString?
    let username: String?
    let nickname: String?
    let realname: String?
    let selfGender: RemoteFlexibleString?
    let name: String?
    let content: String?
    let personGender: RemoteFlexibleString?
    let publishTime: RemoteFlexibleString?
    let likeCount: RemoteFlexibleString?
    let liked: RemoteFlexibleString?
    let commentCount: RemoteFlexibleString?
    let guessCount: RemoteFlexibleString?
    let guessSum: RemoteFlexibleString?
    let canGuess: RemoteFlexibleString?
}

struct ExpressCommentRemoteDTO: Decodable {
    let id: RemoteFlexibleString?
    let username: String?
    let nickname: String?
    let comment: String?
    let publishTime: RemoteFlexibleString?
}
