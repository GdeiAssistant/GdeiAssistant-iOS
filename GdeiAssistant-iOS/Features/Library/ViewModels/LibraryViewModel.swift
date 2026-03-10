import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var keyword: String = ""
    @Published var books: [LibraryBook] = []
    @Published var borrowRecords: [BorrowRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submitState: SubmitState = .idle

    private let repository: any LibraryRepository

    init(repository: any LibraryRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        if books.isEmpty && borrowRecords.isEmpty {
            await refreshAll()
        }
    }

    func refreshAll() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let searchTask = repository.searchBooks(keyword: keyword)
            async let borrowTask = repository.fetchBorrowRecords()
            books = try await searchTask
            borrowRecords = try await borrowTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "图书馆数据加载失败"
        }
    }

    func searchBooks() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            books = try await repository.searchBooks(keyword: keyword)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "检索失败"
        }
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        try await repository.fetchBookDetail(bookID: bookID)
    }

    func renewBorrow(record: BorrowRecord, password: String) async {
        guard
            let sn = record.sn,
            let code = record.code,
            record.renewable
        else {
            submitState = .failure("当前借阅记录暂不支持续借")
            return
        }

        submitState = .submitting

        do {
            try await repository.renewBorrow(
                request: LibraryRenewRequest(sn: sn, code: code, password: password)
            )
            borrowRecords = try await repository.fetchBorrowRecords()
            submitState = .success("续借申请已提交")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "续借失败")
        }
    }

    func clearSubmitState() {
        submitState = .idle
    }
}
