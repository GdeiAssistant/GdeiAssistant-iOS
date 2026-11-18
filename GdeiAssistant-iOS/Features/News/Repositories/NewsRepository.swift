import Foundation

@MainActor
protocol NewsRepository {
    func fetchNews(start: Int, size: Int) async throws -> [NewsItem]
    func fetchNewsDetail(id: String) async throws -> NewsItem
}
