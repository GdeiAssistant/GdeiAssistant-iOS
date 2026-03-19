import Foundation

struct NewsItem: Identifiable, Hashable {
    let id: String
    let type: Int
    let title: String
    let publishDate: String
    let content: String

    var sourceTitle: String {
        switch type {
        case 1:
            return "学校要闻"
        case 2:
            return "院部通知"
        case 3:
            return "通知公告"
        case 4:
            return "学术动态"
        default:
            return "新闻通知"
        }
    }
}
