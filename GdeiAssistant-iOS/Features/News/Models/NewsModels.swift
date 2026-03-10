import Foundation

enum NewsCategory: Int, CaseIterable, Identifiable {
    case teaching = 1
    case exam = 2
    case affairs = 3
    case admin = 4
    case campus = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .teaching: return "教学信息"
        case .exam: return "考试信息"
        case .affairs: return "教务信息"
        case .admin: return "行政通知"
        case .campus: return "综合信息"
        }
    }
}

struct NewsItem: Identifiable, Hashable {
    let id: String
    let category: NewsCategory
    let title: String
    let publishDate: String
    let content: String
}
