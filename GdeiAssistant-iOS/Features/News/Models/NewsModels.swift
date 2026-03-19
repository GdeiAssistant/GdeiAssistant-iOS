import Foundation

enum NewsCategoryType: Int, CaseIterable {
    case schoolHeadlines = 1
    case collegeNotices = 2
    case campusNotices = 3
    case academicUpdates = 4

    var title: String {
        switch self {
        case .schoolHeadlines:
            return "学校要闻"
        case .collegeNotices:
            return "院部通知"
        case .campusNotices:
            return "通知公告"
        case .academicUpdates:
            return "学术动态"
        }
    }
}

struct NewsItem: Identifiable, Hashable {
    let id: String
    let type: Int
    let title: String
    let publishDate: String
    let content: String
    let sourceURL: String?

    var sourceTitle: String {
        NewsCategoryType(rawValue: type)?.title ?? "新闻通知"
    }
}
