import Foundation

enum HomeSection: String, CaseIterable, Identifiable {
    case campusServices
    case campusLife

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campusServices:
            return "校园服务"
        case .campusLife:
            return "校园生活"
        }
    }

    var subtitle: String {
        switch self {
        case .campusServices:
            return "查成绩、课表、四六级、图书馆、校园卡和常用查询工具"
        case .campusLife:
            return "二手交易、快递代取、失物招领、树洞、卖室友、表白墙、话题和校园摄影"
        }
    }
}

struct HomeEntryConfig: Identifiable, Hashable {
    var id: String { destination.featureID }

    let title: String
    let subtitle: String
    let icon: String
    let destination: AppDestination
}

struct HomeEntrySection: Identifiable, Hashable {
    let section: HomeSection
    let entries: [HomeEntryConfig]

    var id: String { section.id }
}

extension HomeEntryConfig {
    init(destination: AppDestination, subtitle: String) {
        self.title = destination.title
        self.subtitle = subtitle
        self.icon = destination.icon
        self.destination = destination
    }

    static let campusServices: [HomeEntryConfig] = [
        HomeEntryConfig(destination: .grade, subtitle: "查每学年每学期成绩和绩点"),
        HomeEntryConfig(destination: .schedule, subtitle: "一眼看清这周每天上什么课"),
        HomeEntryConfig(destination: .cet, subtitle: "输入考号和验证码即可查分"),
        HomeEntryConfig(destination: .graduateExam, subtitle: "查询考研成绩和相关信息"),
        HomeEntryConfig(destination: .spare, subtitle: "看看现在还有哪些空课室"),
        HomeEntryConfig(destination: .library, subtitle: "搜馆藏、看借阅、办续借都在这里"),
        HomeEntryConfig(destination: .card, subtitle: "查余额、查消费、办挂失"),
        HomeEntryConfig(destination: .dataCenter, subtitle: "查电费，也能找校内常用电话"),
        HomeEntryConfig(destination: .evaluate, subtitle: "需要评教时直接来这里完成")
    ]

    static let campusLife: [HomeEntryConfig] = [
        HomeEntryConfig(destination: .marketplace, subtitle: "闲置物品转让，便宜淘点实用好物"),
        HomeEntryConfig(destination: .delivery, subtitle: "发跑腿需求，也能顺手接单赚点零花"),
        HomeEntryConfig(destination: .lostFound, subtitle: "丢东西、捡东西都先来这里看看"),
        HomeEntryConfig(destination: .secret, subtitle: "不想公开说的话，就匿名留在这里"),
        HomeEntryConfig(destination: .dating, subtitle: "看看资料，发起卖室友互动"),
        HomeEntryConfig(destination: .express, subtitle: "想表白、想留言，都可以写在这里"),
        HomeEntryConfig(destination: .topic, subtitle: "最近校园里在聊什么，这里一眼能看见"),
        HomeEntryConfig(destination: .photograph, subtitle: "看看同学镜头里拍下的校园瞬间")
    ]

    static let allSections: [HomeEntrySection] = [
        HomeEntrySection(section: .campusServices, entries: campusServices),
        HomeEntrySection(section: .campusLife, entries: campusLife)
    ]

    static let allEntries: [HomeEntryConfig] = campusServices + campusLife
}
