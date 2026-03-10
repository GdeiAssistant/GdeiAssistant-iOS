import Foundation

@MainActor
final class RemoteLibraryRepository: LibraryRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func searchBooks(keyword: String) async throws -> [LibraryBook] {
        let dto: BookSearchResponseDTO = try await apiClient.get(
            "/book/search",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: "1")
            ],
            requiresAuth: true
        )
        return LibraryRemoteMapper.mapBooks(dto)
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        let dto: LibraryCollectionDetailDTO = try await apiClient.get(
            "/book/detail",
            queryItems: [URLQueryItem(name: "detailURL", value: bookID)],
            requiresAuth: true
        )
        return LibraryRemoteMapper.mapBookDetail(bookID: bookID, dto: dto)
    }

    func fetchBorrowRecords() async throws -> [BorrowRecord] {
        let dtos: [BorrowBookDTO] = try await apiClient.get("/book/borrow", requiresAuth: true)
        return LibraryRemoteMapper.mapBorrowRecords(dtos)
    }

    func renewBorrow(request: LibraryRenewRequest) async throws {
        let dto = LibraryRemoteMapper.mapRenewRequest(request)
        let _: EmptyPayload = try await apiClient.post(
            "/book/renew",
            body: dto,
            requiresAuth: true
        )
    }
}
