import Foundation

enum AppDestination: Hashable {
    case community
    case topic
    case express
    case delivery
    case photograph
    case schedule
    case grade
    case card
    case library
    case cet
    case reading
    case evaluate
    case spare
    case graduateExam
    case news
    case dataCenter
    case marketplace
    case lostFound
    case secret
    case dating
}

extension AppDestination {
    var featureID: String {
        switch self {
        case .community:
            return "community"
        case .topic:
            return "topic"
        case .express:
            return "express"
        case .delivery:
            return "delivery"
        case .photograph:
            return "photograph"
        case .schedule:
            return "schedule"
        case .grade:
            return "grade"
        case .card:
            return "card"
        case .library:
            return "library"
        case .cet:
            return "cet"
        case .reading:
            return "reading"
        case .evaluate:
            return "evaluate"
        case .spare:
            return "spare"
        case .graduateExam:
            return "graduateExam"
        case .news:
            return "news"
        case .dataCenter:
            return "data_center"
        case .marketplace:
            return "marketplace"
        case .lostFound:
            return "lost_found"
        case .secret:
            return "secret"
        case .dating:
            return "dating"
        }
    }

    var title: String {
        switch self {
        case .community:
            return "发现"
        case .topic:
            return "话题"
        case .express:
            return "表白墙"
        case .delivery:
            return "全民快递"
        case .photograph:
            return "拍好校园"
        case .schedule:
            return "课表查询"
        case .grade:
            return "成绩查询"
        case .card:
            return "校园卡"
        case .library:
            return "图书馆"
        case .cet:
            return "四六级查询"
        case .reading:
            return "阅读"
        case .evaluate:
            return "教学评价"
        case .spare:
            return "教室查询"
        case .graduateExam:
            return "考研查询"
        case .news:
            return "新闻通知"
        case .dataCenter:
            return "数据查询"
        case .marketplace:
            return "二手交易"
        case .lostFound:
            return "失物招领"
        case .secret:
            return "校园树洞"
        case .dating:
            return "卖室友"
        }
    }

    var icon: String {
        switch self {
        case .community:
            return "rectangle.3.group.bubble.left"
        case .topic:
            return "number"
        case .express:
            return "heart.text.square"
        case .delivery:
            return "shippingbox.circle"
        case .photograph:
            return "camera"
        case .schedule:
            return "calendar"
        case .grade:
            return "chart.bar"
        case .card:
            return "creditcard"
        case .library:
            return "books.vertical"
        case .cet:
            return "doc.text.magnifyingglass"
        case .reading:
            return "book.pages"
        case .evaluate:
            return "checkmark.seal"
        case .spare:
            return "building.2"
        case .graduateExam:
            return "graduationcap"
        case .news:
            return "newspaper"
        case .dataCenter:
            return "server.rack"
        case .marketplace:
            return "bag"
        case .lostFound:
            return "shippingbox"
        case .secret:
            return "moon.stars"
        case .dating:
            return "person.3"
        }
    }
}
