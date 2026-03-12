import Foundation

struct AnnouncementRemoteDTO: Decodable {
    let id: String?
    let title: String?
    let content: String?
    let publishTime: RemoteFlexibleString?
}

struct ReadingTopicRemoteDTO: Decodable {
    let id: String?
    let title: String?
    let description: String?
    let link: String?
    let createTime: RemoteFlexibleString?
}

struct FestivalRemoteDTO: Decodable {
    let name: String?
    let description: [String]?
}

struct InformationRemoteDTO: Decodable {
    let notice: AnnouncementRemoteDTO?
    let notices: [AnnouncementRemoteDTO]?
    let topics: [ReadingTopicRemoteDTO]?
    let festival: FestivalRemoteDTO?
}

struct InteractionNotificationRemoteDTO: Decodable {
    let id: String?
    let module: String?
    let type: String?
    let title: String?
    let content: String?
    let createdAt: RemoteFlexibleString?
    let isRead: Bool?
    let targetType: String?
    let targetId: String?
    let targetSubId: String?
}
