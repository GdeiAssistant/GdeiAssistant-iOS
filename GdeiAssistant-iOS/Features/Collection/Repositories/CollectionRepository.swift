import Foundation

@MainActor
protocol CollectionRepository {
    func search(keyword: String, page: Int) async throws -> CollectionSearchPage
    func fetchDetail(detailURL: String) async throws -> CollectionDetailInfo
    func fetchBorrowedBooks(password: String?) async throws -> [CollectionBorrowItem]
    func renewBorrow(sn: String, code: String) async throws
}

@MainActor
final class SwitchingCollectionRepository: CollectionRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any CollectionRepository
    private let mockRepository: any CollectionRepository

    init(environment: AppEnvironment, remoteRepository: any CollectionRepository, mockRepository: any CollectionRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func search(keyword: String, page: Int) async throws -> CollectionSearchPage {
        try await currentRepository.search(keyword: keyword, page: page)
    }

    func fetchDetail(detailURL: String) async throws -> CollectionDetailInfo {
        try await currentRepository.fetchDetail(detailURL: detailURL)
    }

    func fetchBorrowedBooks(password: String?) async throws -> [CollectionBorrowItem] {
        try await currentRepository.fetchBorrowedBooks(password: password)
    }

    func renewBorrow(sn: String, code: String) async throws {
        try await currentRepository.renewBorrow(sn: sn, code: code)
    }

    private var currentRepository: any CollectionRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
