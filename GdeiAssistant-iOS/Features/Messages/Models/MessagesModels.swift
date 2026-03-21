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
    case announcement
    case news
    case marketplace
    case lostFound
    case delivery
    case secret
    case express
    case topic
    case photograph
    case datingCenter
}

struct AppNotificationItem: Codable, Identifiable, Hashable {
    let id: String
    let category: NotificationCategory
    let module: String?
    let title: String
    let message: String
    let createdAt: String
    let isRead: Bool
    let destination: MessageNavigationTarget?
    let targetType: String?
    let targetID: String?
    let targetSubID: String?

    var isInteractionItem: Bool {
        switch category {
        case .interaction, .comment, .like:
            return true
        default:
            return false
        }
    }

    var moduleBadgeText: String? {
        switch destination {
        case .announcement:
            return "公告"
        case .news:
            return "新闻"
        default:
            break
        }

        switch normalizedModule {
        case "marketplace":
            return "二手"
        case "lostandfound":
            return "失物招领"
        case "delivery":
            return "全民快递"
        case "secret":
            return "树洞"
        case "express":
            return "表白墙"
        case "topic":
            return "话题"
        case "photograph":
            return "拍好校园"
        case "dating":
            return "卖室友"
        case nil:
            switch category {
            case .system:
                return "系统"
            case .service:
                return "服务"
            case .interaction, .comment, .like:
                return "其它互动"
            case .all:
                return nil
            }
        default:
            return "其它互动"
        }
    }

    var actionBadgeText: String? {
        switch normalizedTargetType {
        case "comment":
            return "评论"
        case "like":
            return "点赞"
        case "guess":
            return "猜名字"
        case "posts":
            return "我的发布"
        case "published":
            return "我发布的"
        case "accepted":
            return "我接的"
        case "sent":
            return "我发出的"
        case "received":
            return "我收到的"
        default:
            switch category {
            case .comment, .like:
                return category.title
            case .interaction:
                return "新动态"
            default:
                return nil
            }
        }
    }

    var readBadgeText: String? {
        guard isInteractionItem else { return nil }
        return isRead ? "已读" : "未读"
    }

    var datingCenterTab: DatingCenterTab {
        switch normalizedTargetType {
        case "sent":
            return .sent
        case "posts", "published":
            return .posts
        default:
            return .received
        }
    }

    func updatingReadState(_ isRead: Bool) -> AppNotificationItem {
        AppNotificationItem(
            id: id,
            category: category,
            module: module,
            title: title,
            message: message,
            createdAt: createdAt,
            isRead: isRead,
            destination: destination,
            targetType: targetType,
            targetID: targetID,
            targetSubID: targetSubID
        )
    }

    private var normalizedModule: String? {
        guard let module else { return nil }
        let trimmed = module.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        switch trimmed {
        case "ershou", "secondhand":
            return "marketplace"
        case "lost_found", "lostfound":
            return "lostandfound"
        case "roommate":
            return "dating"
        default:
            return trimmed
        }
    }

    private var normalizedTargetType: String? {
        guard let targetType else { return nil }
        let trimmed = targetType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct Festival {
    let name: String
    let description: [String]
}

struct AnnouncementDetailItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let content: String
    let createdAt: String
}
