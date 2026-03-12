import Foundation

extension MockSeedData {
    static let announcementDetailsByID: [String: AnnouncementDetailItem] = [
        "announcement_001": AnnouncementDetailItem(
            id: "announcement_001",
            title: "系统维护通知",
            content: "为配合学期中服务器扩容，本周三 18:00 至 20:00 将进行例行维护。维护期间消息中心、校园社区和部分查询服务可能出现短暂不可用，建议提前保存正在编辑的内容。",
            createdAt: "1小时前"
        ),
        "announcement_002": AnnouncementDetailItem(
            id: "announcement_002",
            title: "春季双选会入场安排",
            content: "春季校园双选会将于本周五 14:30 在体育馆举行。请已报名同学提前准备校园卡，按学院分批入场，现场会同步开放企业岗位二维码与志愿者咨询台。",
            createdAt: "今天 09:10"
        ),
        "announcement_003": AnnouncementDetailItem(
            id: "announcement_003",
            title: "图书馆夜间开放时段调整",
            content: "从下周起，图书馆一楼自习区开放时间延长至 23:00，二楼研讨室仍需预约。若遇到插座、座位预约或入馆设备异常，可直接在资讯页提交反馈。",
            createdAt: "昨天"
        ),
        "announcement_004": AnnouncementDetailItem(
            id: "announcement_004",
            title: "校医院门诊排班更新",
            content: "校医院本周起调整晚间门诊排班，工作日 18:30 后优先接待急诊与发热相关问诊，普通门诊请尽量在白天时段前往。",
            createdAt: "昨天 18:40"
        ),
        "announcement_005": AnnouncementDetailItem(
            id: "announcement_005",
            title: "宿舍门禁系统升级提醒",
            content: "北区与中区宿舍门禁将于本周末夜间分批升级，升级期间刷卡开门可能存在短暂延迟，请提前留意楼栋群通知。",
            createdAt: "前天"
        ),
        "announcement_006": AnnouncementDetailItem(
            id: "announcement_006",
            title: "就业指导中心咨询时段开放",
            content: "就业指导中心新增春招一对一简历咨询时段，已开放线上预约。需要模拟面试或简历修改的同学可在工作日预约。",
            createdAt: "2026-03-01"
        )
    ]

    static let notifications: [AppNotificationItem] = [
        AppNotificationItem(
            id: "announcement_notice_001",
            category: .system,
            module: nil,
            title: "系统维护通知",
            message: "本周三 18:00 至 20:00 将进行例行维护，消息中心和部分查询服务可能短暂不可用。",
            createdAt: "1小时前",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "announcement_notice_002",
            category: .system,
            module: nil,
            title: "春季双选会入场安排",
            message: "双选会本周五在体育馆举行，已报名同学请提前准备校园卡并按学院分批入场。",
            createdAt: "今天 09:10",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_002",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "announcement_notice_003",
            category: .system,
            module: nil,
            title: "图书馆夜间开放时段调整",
            message: "下周起一楼自习区开放到 23:00，二楼研讨室仍需预约。",
            createdAt: "昨天",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_003",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "announcement_notice_004",
            category: .system,
            module: nil,
            title: "校医院门诊排班更新",
            message: "晚间门诊优先接待急诊与发热相关问诊，普通门诊请尽量在白天时段前往。",
            createdAt: "昨天 18:40",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_004",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "announcement_notice_005",
            category: .system,
            module: nil,
            title: "宿舍门禁系统升级提醒",
            message: "本周末夜间将分批升级门禁系统，刷卡开门可能出现短暂延迟。",
            createdAt: "前天",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_005",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "announcement_notice_006",
            category: .system,
            module: nil,
            title: "就业指导中心咨询时段开放",
            message: "春招简历咨询与模拟面试已开放线上预约。",
            createdAt: "2026-03-01",
            isRead: true,
            destination: .announcement,
            targetType: nil,
            targetID: "announcement_006",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "msg_interaction_001",
            category: .interaction,
            module: "dating",
            title: "卖室友互动",
            message: "你发出的卖室友申请已被对方查看，去 sent 页看看最新状态。",
            createdAt: "刚刚",
            isRead: false,
            destination: .datingCenter,
            targetType: "sent",
            targetID: "pick_002",
            targetSubID: "dating_001"
        ),
        AppNotificationItem(
            id: "msg_interaction_002",
            category: .interaction,
            module: "delivery",
            title: "全民快递提醒",
            message: "你发布的订单已被接单，建议尽快和接单同学确认送达时间。",
            createdAt: "6分钟前",
            isRead: false,
            destination: .delivery,
            targetType: "published",
            targetID: "delivery_002",
            targetSubID: "trade_001"
        ),
        AppNotificationItem(
            id: "msg_interaction_003",
            category: .interaction,
            module: "delivery",
            title: "全民快递提醒",
            message: "你接的订单已完成，系统已同步为已完成状态。",
            createdAt: "12分钟前",
            isRead: false,
            destination: .delivery,
            targetType: "accepted",
            targetID: "delivery_004",
            targetSubID: "trade_004"
        ),
        AppNotificationItem(
            id: "msg_interaction_004",
            category: .comment,
            module: "secret",
            title: "树洞互动",
            message: "有人回复了你的树洞，打开详情即可查看最新评论。",
            createdAt: "10分钟前",
            isRead: false,
            destination: .secret,
            targetType: "comment",
            targetID: "secret_001",
            targetSubID: "secret_comment_002"
        ),
        AppNotificationItem(
            id: "msg_interaction_005",
            category: .comment,
            module: "express",
            title: "表白墙互动",
            message: "有人给你的表白留了言，打开详情即可查看最新评论。",
            createdAt: "14分钟前",
            isRead: false,
            destination: .express,
            targetType: "comment",
            targetID: "express_001",
            targetSubID: "express_comment_001"
        ),
        AppNotificationItem(
            id: "msg_interaction_006",
            category: .interaction,
            module: "express",
            title: "表白墙互动",
            message: "有人参与了你的猜名字互动，去看看最新猜测次数。",
            createdAt: "18分钟前",
            isRead: true,
            destination: .express,
            targetType: "guess",
            targetID: "express_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "msg_interaction_007",
            category: .like,
            module: "topic",
            title: "话题互动",
            message: "你的话题收到了新的点赞。",
            createdAt: "25分钟前",
            isRead: true,
            destination: .topic,
            targetType: "like",
            targetID: "topic_001",
            targetSubID: nil
        ),
        AppNotificationItem(
            id: "msg_interaction_008",
            category: .comment,
            module: "photograph",
            title: "拍好校园互动",
            message: "有人评论了你的作品，打开详情即可查看最新评论。",
            createdAt: "40分钟前",
            isRead: false,
            destination: .photograph,
            targetType: "comment",
            targetID: "photo_001",
            targetSubID: "photo_comment_001"
        )
    ]
}
