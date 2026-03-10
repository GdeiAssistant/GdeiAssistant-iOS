import Foundation

struct TopicRemoteDTO: Decodable {
    let id: RemoteFlexibleString?
    let username: String?
    let topic: String?
    let content: String?
    let count: RemoteFlexibleString?
    let publishTime: RemoteFlexibleString?
    let likeCount: RemoteFlexibleString?
    let liked: RemoteFlexibleString?
    let firstImageUrl: String?
    let imageUrls: [String]?
}
