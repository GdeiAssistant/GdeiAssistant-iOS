import Foundation

@MainActor
final class RemoteNewsRepository: NewsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchNews(start: Int, size: Int) async throws -> [NewsItem] {
        let information: InformationRemoteDTO = try await apiClient.get(
            "/information/list",
            requiresAuth: true
        )

        let sourceItems: [AnnouncementRemoteDTO]
        if let notices = information.notices, !notices.isEmpty {
            sourceItems = notices
        } else if let notice = information.notice {
            sourceItems = [notice]
        } else {
            sourceItems = []
        }

        let mappedItems = NewsRemoteMapper.mapItems(sourceItems)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < mappedItems.count else { return [] }
        return Array(mappedItems.dropFirst(safeStart).prefix(safeSize))
    }
}
