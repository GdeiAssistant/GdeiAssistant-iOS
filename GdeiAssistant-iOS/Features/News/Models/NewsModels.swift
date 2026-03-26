import Foundation

enum NewsCategoryType: Int, CaseIterable {
    case schoolHeadlines = 1
    case collegeNotices = 2
    case campusNotices = 3
    case academicUpdates = 4

    var title: String {
        switch self {
        case .schoolHeadlines:
            return localizedString("news.category.schoolHeadlines")
        case .collegeNotices:
            return localizedString("news.category.collegeNotices")
        case .campusNotices:
            return localizedString("news.category.campusNotices")
        case .academicUpdates:
            return localizedString("news.category.academicUpdates")
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
        NewsCategoryType(rawValue: type)?.title ?? localizedString("news.category.default")
    }
}
