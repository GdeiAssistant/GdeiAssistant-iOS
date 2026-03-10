import Foundation

extension MockSeedData {
    static let notifications: [AppNotificationItem] = [
        AppNotificationItem(
            id: "notify_001",
            category: .system,
            title: "系统通知",
            message: "本周三 18:00 至 20:00 将进行服务器例行维护，部分服务可能短暂不可用。",
            createdAt: "1小时前",
            isRead: true,
            destination: nil,
            targetType: nil,
            targetID: nil,
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_002",
            category: .system,
            title: "服务提醒",
            message: "你借阅的《数据库系统概论》将在 2 天后到期，记得及时续借。",
            createdAt: "1小时前",
            isRead: false,
            destination: nil,
            targetType: nil,
            targetID: nil,
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_003",
            category: .interaction,
            title: "互动提醒",
            message: "有人向你发起了卖室友互动请求，请前往互动中心查看。",
            createdAt: "2小时前",
            isRead: true,
            destination: .datingReceived,
            targetType: "received",
            targetID: "pick_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_004",
            category: .comment,
            title: "树洞互动",
            message: "有人回复了你的树洞，去看看对方说了什么。",
            createdAt: "10分钟前",
            isRead: false,
            destination: .secret,
            targetType: "post",
            targetID: "secret_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_005",
            category: .like,
            title: "表白墙互动",
            message: "你的表白收到了新的点赞。",
            createdAt: "20分钟前",
            isRead: false,
            destination: .express,
            targetType: "post",
            targetID: "express_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_006",
            category: .comment,
            title: "话题互动",
            message: "你发布的话题有了新的评论。",
            createdAt: "25分钟前",
            isRead: true,
            destination: .topic,
            targetType: "post",
            targetID: "topic_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_007",
            category: .like,
            title: "拍好校园互动",
            message: "你的作品获得了新的点赞。",
            createdAt: "40分钟前",
            isRead: false,
            destination: .photograph,
            targetType: "post",
            targetID: "photo_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_008",
            category: .interaction,
            title: "全民快递提醒",
            message: "你发布的订单已被接单，请及时留意配送进度。",
            createdAt: "50分钟前",
            isRead: true,
            destination: .delivery,
            targetType: "order",
            targetID: "delivery_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_009",
            category: .interaction,
            title: "二手交易提醒",
            message: "你发布的闲置商品有了新的状态变更。",
            createdAt: "1小时前",
            isRead: true,
            destination: .marketplace,
            targetType: "item",
            targetID: "market_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "notify_010",
            category: .interaction,
            title: "失物招领提醒",
            message: "你发布的失物招领信息有了新的处理进展。",
            createdAt: "2小时前",
            isRead: true,
            destination: .lostFound,
            targetType: "item",
            targetID: "lf_001",
            targetSubID: nil
        )
    ]

    static let interactionThreads: [InteractionThreadItem] = [
        InteractionThreadItem(
            id: "thread_001",
            title: "卖室友互动",
            lastMessage: "你收到了一条新的互动消息，请前往互动中心查看。",
            updatedAt: "刚刚",
            unreadCount: 1,
            isRead: false,
            avatarURL: "https://example.com/avatar/dating-assistant.png",
            destinationTab: .received
        ),
        InteractionThreadItem(
            id: "thread_002",
            title: "卖室友状态更新",
            lastMessage: "你发出的卖室友请求已有新状态，请前往互动中心查看。",
            updatedAt: "30分钟前",
            unreadCount: 0,
            isRead: true,
            avatarURL: "https://example.com/avatar/market-helper.png",
            destinationTab: .sent
        )
    ]
}
