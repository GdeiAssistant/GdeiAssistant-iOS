import Foundation

@MainActor
final class RemoteCollectionRepository: CollectionRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func search(keyword: String, page: Int) async throws -> CollectionSearchPage {
        let dto: CollectionSearchResponseDTO = try await apiClient.get(
            "/library/search",
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
            "/library/detail",
            queryItems: [URLQueryItem(name: "detailURL", value: detailURL)],
            requiresAuth: true
        )
        return CollectionRemoteMapper.mapDetail(dto)
    }

    func fetchBorrowedBooks(password: String) async throws -> [CollectionBorrowItem] {
        let normalizedPassword = FormValidationSupport.trimmed(password)
        let dtos: [CollectionBorrowDTO] = try await apiClient.get(
            "/library/borrow",
            queryItems: [URLQueryItem(name: "password", value: normalizedPassword)],
            requiresAuth: true
        )
        return CollectionRemoteMapper.mapBorrowItems(dtos)
    }

    func renewBorrow(sn: String, code: String, password: String) async throws {
        let normalizedPassword = FormValidationSupport.trimmed(password)
        let _: EmptyPayload = try await apiClient.post(
            "/library/renew",
            queryItems: [
                URLQueryItem(name: "sn", value: sn),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "password", value: normalizedPassword)
            ],
            requiresAuth: true
        )
    }
}
