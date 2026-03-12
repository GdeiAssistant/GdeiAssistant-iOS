import Foundation

struct NewsItem: Identifiable, Hashable {
    let id: String
    let title: String
    let publishDate: String
    let content: String
}
