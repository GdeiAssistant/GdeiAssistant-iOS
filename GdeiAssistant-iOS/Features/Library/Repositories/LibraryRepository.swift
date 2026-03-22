import Foundation

@MainActor
protocol LibraryRepository {
    func searchBooks(keyword: String, page: Int) async throws -> [LibraryBook]
    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail
    func fetchBorrowRecords(password: String) async throws -> [BorrowRecord]
    func renewBorrow(request: LibraryRenewRequest) async throws
}

@MainActor
final class SwitchingLibraryRepository: LibraryRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any LibraryRepository
    private let mockRepository: any LibraryRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any LibraryRepository,
        mockRepository: any LibraryRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func searchBooks(keyword: String, page: Int) async throws -> [LibraryBook] {
        try await currentRepository.searchBooks(keyword: keyword)
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        try await currentRepository.fetchBookDetail(bookID: bookID)
    }

    func fetchBorrowRecords(password: String) async throws -> [BorrowRecord] {
        try await currentRepository.fetchBorrowRecords(password: password)
    }

    func renewBorrow(request: LibraryRenewRequest) async throws {
        try await currentRepository.renewBorrow(request: request)
    }

    private var currentRepository: any LibraryRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
