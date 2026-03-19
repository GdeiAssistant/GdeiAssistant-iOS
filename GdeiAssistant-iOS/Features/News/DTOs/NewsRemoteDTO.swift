import Foundation

struct NewsRemoteDTO: Decodable {
    let id: String?
    let type: Int?
    let title: String?
    let publishDate: String?
    let content: String?
    let sourceUrl: String?
}
