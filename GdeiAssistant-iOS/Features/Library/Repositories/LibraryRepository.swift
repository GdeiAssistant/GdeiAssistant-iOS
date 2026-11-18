import Foundation

@MainActor
protocol LibraryRepository {
    func searchBooks(keyword: String, page: Int) async throws -> [LibraryBook]
    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail
    func fetchBorrowRecords(password: String) async throws -> [BorrowRecord]
    func renewBorrow(request: LibraryRenewRequest) async throws
}
