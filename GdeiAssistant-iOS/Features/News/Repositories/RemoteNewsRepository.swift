import Foundation

@MainActor
final class RemoteNewsRepository: NewsRepository {
    private let categoryTypes = [1, 2, 3, 4, 5]
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
                "/news/type/\(type)/start/0/size/\(perCategorySize)",
                requiresAuth: true
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
}
