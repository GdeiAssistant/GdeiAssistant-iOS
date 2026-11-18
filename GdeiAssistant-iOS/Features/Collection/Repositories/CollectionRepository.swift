import Foundation

@MainActor
protocol CollectionRepository {
    func search(keyword: String, page: Int) async throws -> CollectionSearchPage
    func fetchDetail(detailURL: String) async throws -> CollectionDetailInfo
    func fetchBorrowedBooks(password: String) async throws -> [CollectionBorrowItem]
    func renewBorrow(sn: String, code: String, password: String) async throws
}
