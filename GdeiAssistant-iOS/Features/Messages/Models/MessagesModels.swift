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
            return localizedString("messages.category.all")
        case .comment:
            return localizedString("messages.category.comment")
        case .like:
            return localizedString("messages.category.like")
        case .system:
            return localizedString("messages.category.system")
        case .service:
            return localizedString("messages.category.service")
        case .interaction:
            return localizedString("messages.category.interaction")
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
            return localizedString("messages.badge.announcement")
        case .news:
            return localizedString("messages.badge.news")
        default:
            break
        }

        switch normalizedModule {
        case "marketplace":
            return localizedString("messages.badge.marketplace")
        case "lostandfound":
            return localizedString("messages.badge.lostFound")
        case "delivery":
            return localizedString("messages.badge.delivery")
        case "secret":
            return localizedString("messages.badge.secret")
        case "express":
            return localizedString("messages.badge.express")
        case "topic":
            return localizedString("messages.badge.topic")
        case "photograph":
            return localizedString("messages.badge.photograph")
        case "dating":
            return localizedString("feature.dating")
        case nil:
            switch category {
            case .system:
                return localizedString("messages.category.system")
            case .service:
                return localizedString("messages.category.service")
            case .interaction, .comment, .like:
                return localizedString("messages.badge.otherInteraction")
            case .all:
                return nil
            }
        default:
            return localizedString("messages.badge.otherInteraction")
        }
    }

    var actionBadgeText: String? {
        switch normalizedTargetType {
        case "comment":
            return localizedString("messages.action.comment")
        case "like":
            return localizedString("messages.action.like")
        case "guess":
            return localizedString("messages.action.guess")
        case "posts":
            return localizedString("messages.action.posts")
        case "published":
            return localizedString("messages.action.published")
        case "accepted":
            return localizedString("messages.action.accepted")
        case "sent":
            return localizedString("messages.action.sent")
        case "received":
            return localizedString("messages.action.received")
        default:
            switch category {
            case .comment, .like:
                return category.title
            case .interaction:
                return localizedString("messages.action.newActivity")
            default:
                return nil
            }
        }
    }

    var readBadgeText: String? {
        guard isInteractionItem else { return nil }
        return isRead ? localizedString("messages.read.read") : localizedString("messages.read.unread")
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
