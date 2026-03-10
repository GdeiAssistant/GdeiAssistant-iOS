import Foundation

enum NotificationCategory: String, Codable, CaseIterable, Identifiable {
    case all
    case comment
    case like
    case system
    case service
    case interaction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .comment:
            return "评论"
        case .like:
            return "点赞"
        case .system:
            return "系统"
        case .service:
            return "服务"
        case .interaction:
            return "互动"
        }
    }
}

enum MessageNavigationTarget: String, Codable, Hashable {
    case news
    case reading
    case marketplace
    case lostFound
    case delivery
    case secret
    case express
    case topic
    case photograph
    case datingReceived
    case datingSent
}

struct AppNotificationItem: Codable, Identifiable, Hashable {
    let id: String
    let category: NotificationCategory
    let title: String
    let message: String
    let createdAt: String
    let isRead: Bool
    let destination: MessageNavigationTarget?
    let targetType: String?
    let targetID: String?
    let targetSubID: String?
}

struct InteractionThreadItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let lastMessage: String
    let updatedAt: String
    let unreadCount: Int
    let isRead: Bool
    let avatarURL: String?
    let destinationTab: DatingCenterTab
}
