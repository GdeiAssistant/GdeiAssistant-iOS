import Foundation

@MainActor
final class RemoteLibraryRepository: LibraryRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func searchBooks(keyword: String, page: Int) async throws -> [LibraryBook] {
        let dto: BookSearchResponseDTO = try await apiClient.get(
            "/library/search",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: String(page))
            ],
            requiresAuth: true
        )
        return LibraryRemoteMapper.mapBooks(dto)
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        let dto: LibraryCollectionDetailDTO = try await apiClient.get(
            "/library/detail",
            queryItems: [URLQueryItem(name: "detailURL", value: bookID)],
            requiresAuth: true
        )
        return LibraryRemoteMapper.mapBookDetail(bookID: bookID, dto: dto)
    }

    func fetchBorrowRecords(password: String) async throws -> [BorrowRecord] {
        let dtos: [BorrowBookDTO] = try await apiClient.get(
            "/library/borrow",
            queryItems: [URLQueryItem(name: "password", value: password)],
            requiresAuth: true
        )
        return LibraryRemoteMapper.mapBorrowRecords(dtos)
    }

    func renewBorrow(request: LibraryRenewRequest) async throws {
        let dto = LibraryRemoteMapper.mapRenewRequest(request)
        let _: EmptyPayload = try await apiClient.post(
            "/library/renew",
            body: dto,
            requiresAuth: true
        )
    }
}
