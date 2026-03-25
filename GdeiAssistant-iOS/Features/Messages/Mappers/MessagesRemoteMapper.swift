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
                message: RemoteMapperSupport.firstNonEmpty(item.content, localizedString("messages.mapper.newInteractionMessage")),
                createdAt: RemoteMapperSupport.dateText(item.createdAt, fallback: localizedString("common.justNow")),
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
            title: RemoteMapperSupport.firstNonEmpty(dto.title, localizedString("messages.mapper.announcementTitle")),
            content: RemoteMapperSupport.firstNonEmpty(dto.content, localizedString("messages.mapper.announcementEmptyContent")),
            createdAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: localizedString("common.justNow"))
        )
    }

    nonisolated static func mapFestival(_ dto: FestivalRemoteDTO?) -> Festival? {
        guard let dto, let name = dto.name, !name.isEmpty else { return nil }
        return Festival(name: name, description: dto.description ?? [])
    }

    nonisolated private static func mapAnnouncement(_ announcement: AnnouncementRemoteDTO) -> AppNotificationItem {
        let targetID = RemoteMapperSupport.sanitizedText(announcement.id)
        return AppNotificationItem(
            id: RemoteMapperSupport.firstNonEmpty(announcement.id, UUID().uuidString),
            category: .system,
            module: nil,
            title: RemoteMapperSupport.firstNonEmpty(announcement.title, localizedString("messages.mapper.announcementTitle")),
            message: RemoteMapperSupport.firstNonEmpty(announcement.content, localizedString("messages.mapper.announcementEmptyContent")),
            createdAt: RemoteMapperSupport.dateText(announcement.publishTime, fallback: localizedString("common.justNow")),
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
            return localizedString("messages.mapper.secretInteraction")
        case "express":
            return localizedString("messages.mapper.expressInteraction")
        case "topic":
            return localizedString("messages.mapper.topicInteraction")
        case "photograph":
            return localizedString("messages.mapper.photographInteraction")
        case "delivery":
            return localizedString("messages.mapper.deliveryInteraction")
        case "marketplace":
            return localizedString("messages.mapper.marketplaceInteraction")
        case "lostandfound":
            return localizedString("messages.mapper.lostFoundInteraction")
        case "dating":
            return localizedString("feature.dating")
        default:
            return localizedString("messages.interactionTitle")
        }
    }

    nonisolated private static func interactionDestination(module: String?) -> MessageNavigationTarget? {
        switch module {
        case "marketplace":
            return .marketplace
        case "lostandfound":
            return .lostFound
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
