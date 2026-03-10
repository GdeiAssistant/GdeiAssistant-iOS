import Foundation

@MainActor
final class RemoteCollectionRepository: CollectionRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func search(keyword: String, page: Int) async throws -> CollectionSearchPage {
        let dto: CollectionSearchResponseDTO = try await apiClient.get(
            "/collection/search",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: String(max(page, 1)))
            ],
            requiresAuth: true
        )
        return CollectionRemoteMapper.mapSearchPage(dto)
    }

    func fetchDetail(detailURL: String) async throws -> CollectionDetailInfo {
        let dto: CollectionDetailDTO = try await apiClient.get(
            "/collection/detail",
            queryItems: [URLQueryItem(name: "detailURL", value: detailURL)],
            requiresAuth: true
        )
        return CollectionRemoteMapper.mapDetail(dto)
    }

    func fetchBorrowedBooks(password: String?) async throws -> [CollectionBorrowItem] {
        let queryItems: [URLQueryItem] = {
            guard let password, FormValidationSupport.hasText(password) else {
                return []
            }
            return [URLQueryItem(name: "password", value: password)]
        }()
        let dtos: [CollectionBorrowDTO] = try await apiClient.get(
            "/collection/borrow",
            queryItems: queryItems,
            requiresAuth: true
        )
        return CollectionRemoteMapper.mapBorrowItems(dtos)
    }

    func renewBorrow(sn: String, code: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/collection/renew",
            queryItems: [
                URLQueryItem(name: "sn", value: sn),
                URLQueryItem(name: "code", value: code)
            ],
            requiresAuth: true
        )
    }
}
