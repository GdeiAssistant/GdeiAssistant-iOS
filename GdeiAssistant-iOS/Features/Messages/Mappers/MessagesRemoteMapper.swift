import Foundation

enum MessagesRemoteMapper {
    nonisolated static func mapAnnouncementItems(_ items: [AnnouncementRemoteDTO]) -> [AppNotificationItem] {
        items.map(mapAnnouncement)
    }

    nonisolated static func mapInteractionItems(_ items: [InteractionNotificationRemoteDTO]) -> [AppNotificationItem] {
        items.map { item in
            let module = normalizedInteractionModule(item.module)
            return AppNotificationItem(
                id: RemoteMapperSupport.firstNonEmpty(item.id, UUID().uuidString),
                category: notificationCategory(item.type),
                module: module,
                title: RemoteMapperSupport.firstNonEmpty(item.title, interactionTitle(module: module)),
                message: RemoteMapperSupport.firstNonEmpty(item.content, "你有一条新的互动消息"),
                createdAt: RemoteMapperSupport.dateText(item.createdAt, fallback: "刚刚"),
                isRead: item.isRead ?? false,
                destination: interactionDestination(module: module),
                targetType: normalizedKeyword(item.targetType),
                targetID: RemoteMapperSupport.sanitizedText(item.targetId),
                targetSubID: RemoteMapperSupport.sanitizedText(item.targetSubId)
            )
        }
    }

    nonisolated static func mapAnnouncementDetail(_ dto: AnnouncementRemoteDTO) -> AnnouncementDetailItem {
        AnnouncementDetailItem(
            id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
            title: RemoteMapperSupport.firstNonEmpty(dto.title, "系统公告"),
            content: RemoteMapperSupport.firstNonEmpty(dto.content, "暂无公告内容"),
            createdAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚")
        )
    }

    nonisolated private static func mapAnnouncement(_ announcement: AnnouncementRemoteDTO) -> AppNotificationItem {
        let targetID = RemoteMapperSupport.sanitizedText(announcement.id)
        return AppNotificationItem(
            id: RemoteMapperSupport.firstNonEmpty(announcement.id, UUID().uuidString),
            category: .system,
            module: nil,
            title: RemoteMapperSupport.firstNonEmpty(announcement.title, "系统公告"),
            message: RemoteMapperSupport.firstNonEmpty(announcement.content, "暂无公告内容"),
            createdAt: RemoteMapperSupport.dateText(announcement.publishTime, fallback: "刚刚"),
            isRead: false,
            destination: targetID == nil ? nil : .announcement,
            targetType: nil,
            targetID: targetID,
            targetSubID: nil
        )
    }

    nonisolated private static func notificationCategory(_ type: String?) -> NotificationCategory {
        switch normalizedKeyword(type) {
        case "comment":
            return .comment
        case "like":
            return .like
        default:
            return .interaction
        }
    }

    nonisolated private static func interactionTitle(module: String?) -> String {
        switch module {
        case "secret":
            return "树洞互动"
        case "express":
            return "表白墙互动"
        case "topic":
            return "话题互动"
        case "photograph":
            return "拍好校园互动"
        case "delivery":
            return "全民快递提醒"
        case "marketplace":
            return "二手交易提醒"
        case "lostandfound":
            return "失物招领提醒"
        case "dating":
            return "卖室友互动"
        default:
            return "互动消息"
        }
    }

    nonisolated private static func interactionDestination(module: String?) -> MessageNavigationTarget? {
        switch module {
        case "secret":
            return .secret
        case "express":
            return .express
        case "topic":
            return .topic
        case "photograph":
            return .photograph
        case "delivery":
            return .delivery
        case "dating":
            return .datingCenter
        default:
            return nil
        }
    }

    nonisolated private static func normalizedInteractionModule(_ value: String?) -> String? {
        switch normalizedKeyword(value) {
        case "ershou", "secondhand":
            return "marketplace"
        case "lost_found", "lostfound":
            return "lostandfound"
        case "roommate":
            return "dating"
        default:
            return normalizedKeyword(value)
        }
    }

    nonisolated private static func normalizedKeyword(_ value: String?) -> String? {
        RemoteMapperSupport.sanitizedText(value)?.lowercased()
    }
}
