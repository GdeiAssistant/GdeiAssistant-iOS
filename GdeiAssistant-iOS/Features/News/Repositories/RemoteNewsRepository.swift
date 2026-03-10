import Foundation

@MainActor
final class RemoteNewsRepository: NewsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchNews(category: NewsCategory, start: Int, size: Int) async throws -> [NewsItem] {
        let dtos: [NewsRemoteDTO] = try await apiClient.get(
            "/news/type/\(category.rawValue)/start/\(max(start, 0))/size/\(max(size, 1))",
            requiresAuth: false
        )
        return NewsRemoteMapper.mapItems(dtos, category: category)
    }
}
