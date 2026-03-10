import Foundation

struct PhotographRemoteDTO: Decodable {
    let id: RemoteFlexibleString?
    let title: String?
    let content: String?
    let count: RemoteFlexibleString?
    let type: RemoteFlexibleString?
    let username: String?
    let createTime: RemoteFlexibleString?
    let likeCount: RemoteFlexibleString?
    let commentCount: RemoteFlexibleString?
    let liked: RemoteFlexibleString?
    let firstImageUrl: String?
    let imageUrls: [String]?
    let photographCommentList: [PhotographCommentRemoteDTO]?
}

struct PhotographCommentRemoteDTO: Decodable {
    let commentId: RemoteFlexibleString?
    let photoId: RemoteFlexibleString?
    let username: String?
    let nickname: String?
    let comment: String?
    let createTime: RemoteFlexibleString?
}
