import Foundation

@MainActor
final class RemoteNewsRepository: NewsRepository {
    private let categoryTypes = NewsCategoryType.allCases.map(\.rawValue)
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchNews(start: Int, size: Int) async throws -> [NewsItem] {
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        let perCategorySize = max(safeStart + safeSize, safeSize)

        var mergedItems: [NewsItem] = []
        mergedItems.reserveCapacity(categoryTypes.count * perCategorySize)
        var seenIDs = Set<String>()

        for type in categoryTypes {
            let dtos: [NewsRemoteDTO] = try await apiClient.get(
                "/information/news/type/\(type)/start/0/size/\(perCategorySize)",
                requiresAuth: false
            )
            for item in NewsRemoteMapper.mapItems(dtos) {
                if seenIDs.insert(item.id).inserted {
                    mergedItems.append(item)
                }
            }
        }

        let sortedItems = mergedItems.sorted { lhs, rhs in
            lhs.publishDate > rhs.publishDate
        }
        guard safeStart < sortedItems.count else { return [] }
        return Array(sortedItems.dropFirst(safeStart).prefix(safeSize))
    }

    func fetchNewsDetail(id: String) async throws -> NewsItem {
        let dto: NewsRemoteDTO = try await apiClient.get(
            "/information/news/id/\(id)",
            requiresAuth: false
        )
        let items = NewsRemoteMapper.mapItems([dto])
        guard let item = items.first else {
            throw NetworkError.server(code: 404, message: localizedString("news.notFound"))
        }
        return item
    }
}
