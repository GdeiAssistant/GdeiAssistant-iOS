import Foundation

enum MessagesRemoteMapper {
    nonisolated static func mapNotifications(
        announcement: AnnouncementRemoteDTO?,
        information: InformationRemoteDTO?,
        interactionItems: [InteractionNotificationRemoteDTO]
    ) -> [AppNotificationItem] {
        var items = [AppNotificationItem]()

        if let announcement {
            items.append(
                AppNotificationItem(
                    id: RemoteMapperSupport.firstNonEmpty(announcement.id, UUID().uuidString),
                    category: .system,
                    title: RemoteMapperSupport.firstNonEmpty(announcement.title, "系统公告"),
                    message: RemoteMapperSupport.firstNonEmpty(announcement.content, "暂无公告内容"),
                    createdAt: RemoteMapperSupport.dateText(announcement.publishTime, fallback: "刚刚"),
                    isRead: false,
                    destination: nil,
                    targetType: nil,
                    targetID: nil,
                    targetSubID: nil
                )
            )
        }

        if let festival = information?.festival {
            let festivalMessage = ([festival.name] + (festival.description ?? [])).compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }.joined(separator: " · ")
            if !festivalMessage.isEmpty {
                items.append(
                    AppNotificationItem(
                        id: "festival_notice",
                        category: .system,
                        title: "服务提醒",
                        message: festivalMessage,
                        createdAt: "刚刚",
                        isRead: false,
                        destination: nil,
                        targetType: nil,
                        targetID: nil,
                        targetSubID: nil
                    )
                )
            }
        }

        for topic in information?.topics?.prefix(2) ?? [] {
            items.append(
                AppNotificationItem(
                    id: RemoteMapperSupport.firstNonEmpty(topic.id, UUID().uuidString),
                    category: .service,
                    title: RemoteMapperSupport.firstNonEmpty(topic.title, "专题阅读"),
                    message: RemoteMapperSupport.firstNonEmpty(topic.description, "查看学校整理的专题内容"),
                    createdAt: RemoteMapperSupport.dateText(topic.createTime, fallback: "最近更新"),
                    isRead: true,
                    destination: .reading,
                    targetType: nil,
                    targetID: nil,
                    targetSubID: nil
                )
            )
        }

        items.append(contentsOf: mapInteractionNotifications(interactionItems))
        return items
    }

    nonisolated static func mapThreads(_ dtos: [DatingMessageDTO]) -> [InteractionThreadItem] {
        dtos.map { item in
            let pick = item.datingPick ?? item.roommatePick
            let profile = pick?.datingProfile ?? pick?.roommateProfile
            let isRead = (item.state ?? 0) != 0
            let title = RemoteMapperSupport.firstNonEmpty(profile?.nickname, pick?.username, item.username, "互动消息")
            let content = RemoteMapperSupport.firstNonEmpty(pick?.content, messageTypeText(item.type), "收到一条新的互动消息")

            return InteractionThreadItem(
                id: String(item.messageId ?? item.roommatePick?.pickId ?? Int.random(in: 1...999_999)),
                title: title,
                lastMessage: content,
                updatedAt: RemoteMapperSupport.firstNonEmpty(RemoteMapperSupport.dateText(RemoteFlexibleString(item.createTime ?? ""), fallback: ""), "最近更新"),
                unreadCount: isRead ? 0 : 1,
                isRead: isRead,
                avatarURL: RemoteMapperSupport.sanitizedText(profile?.pictureURL),
                destinationTab: destinationTab(item.type)
            )
        }
    }

    nonisolated private static func messageTypeText(_ value: Int?) -> String {
        switch value {
        case 0:
            return "收到新的卖室友互动"
        case 1:
            return "你的卖室友互动状态已更新"
        default:
            return "新的互动消息"
        }
    }

    nonisolated private static func mapInteractionNotifications(_ items: [InteractionNotificationRemoteDTO]) -> [AppNotificationItem] {
        items.compactMap { item in
            guard let destination = interactionDestination(module: item.module, targetType: item.targetType) else {
                return nil
            }

            return AppNotificationItem(
                id: RemoteMapperSupport.firstNonEmpty(item.id, UUID().uuidString),
                category: notificationCategory(item.type),
                title: RemoteMapperSupport.firstNonEmpty(item.title, interactionTitle(module: item.module)),
                message: RemoteMapperSupport.firstNonEmpty(item.content, "你有一条新的互动消息"),
                createdAt: RemoteMapperSupport.dateText(item.createdAt, fallback: "刚刚"),
                isRead: item.isRead ?? false,
                destination: destination,
                targetType: RemoteMapperSupport.sanitizedText(item.targetType),
                targetID: RemoteMapperSupport.sanitizedText(item.targetId),
                targetSubID: RemoteMapperSupport.sanitizedText(item.targetSubId)
            )
        }
    }

    nonisolated private static func notificationCategory(_ type: String?) -> NotificationCategory {
        switch RemoteMapperSupport.sanitizedText(type) {
        case "comment":
            return .comment
        case "like":
            return .like
        default:
            return .interaction
        }
    }

    nonisolated private static func interactionTitle(module: String?) -> String {
        switch RemoteMapperSupport.sanitizedText(module) {
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

    nonisolated private static func interactionDestination(module: String?, targetType: String?) -> MessageNavigationTarget? {
        switch RemoteMapperSupport.sanitizedText(module) {
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
        case "marketplace":
            return .marketplace
        case "lostandfound":
            return .lostFound
        case "dating":
            return RemoteMapperSupport.sanitizedText(targetType) == "sent" ? .datingSent : .datingReceived
        default:
            return nil
        }
    }

    nonisolated private static func destinationTab(_ value: Int?) -> DatingCenterTab {
        switch value {
        case 1:
            return .sent
        default:
            return .received
        }
    }
}
