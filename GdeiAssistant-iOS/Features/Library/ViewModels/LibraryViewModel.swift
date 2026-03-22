import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var keyword: String = ""
    @Published var currentPage: Int = 1
    @Published var books: [LibraryBook] = []
    @Published var borrowPassword: String = ""
    @Published var borrowRecords: [BorrowRecord] = []
    @Published var isLoading = false
    @Published var isBorrowLoading = false
    @Published var hasLoadedBorrowRecords = false
    @Published var errorMessage: String?
    @Published var borrowErrorMessage: String?
    @Published var submitState: SubmitState = .idle

    private let repository: any LibraryRepository

    init(repository: any LibraryRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        if books.isEmpty {
            await searchBooks()
        }
    }

    func refreshAll() async {
        await searchBooks()
        if hasLoadedBorrowRecords && !FormValidationSupport.trimmed(borrowPassword).isEmpty {
            await fetchBorrowRecords()
        }
    }

    func searchBooks() async {
        currentPage = 1
        await fetchPage(currentPage)
    }

    func goToPreviousPage() async {
        guard currentPage > 1 else { return }
        currentPage -= 1
        await fetchPage(currentPage)
    }

    func goToNextPage() async {
        currentPage += 1
        await fetchPage(currentPage)
    }

    private func fetchPage(_ page: Int) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            books = try await repository.searchBooks(keyword: keyword, page: page)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "检索失败"
        }
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        try await repository.fetchBookDetail(bookID: bookID)
    }

    func fetchBorrowRecords() async {
        let normalizedPassword = FormValidationSupport.trimmed(borrowPassword)
        guard !normalizedPassword.isEmpty else {
            borrowErrorMessage = "请输入图书馆密码"
            return
        }

        isBorrowLoading = true
        borrowErrorMessage = nil

        defer { isBorrowLoading = false }

        do {
            borrowRecords = try await repository.fetchBorrowRecords(password: normalizedPassword)
            borrowPassword = normalizedPassword
            hasLoadedBorrowRecords = true
        } catch {
            borrowErrorMessage = (error as? LocalizedError)?.errorDescription ?? "借阅记录加载失败"
        }
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

        let normalizedPassword = FormValidationSupport.trimmed(password)
        guard !normalizedPassword.isEmpty else {
            submitState = .failure("请输入图书馆密码")
            return
        }

        submitState = .submitting

        do {
            try await repository.renewBorrow(
                request: LibraryRenewRequest(sn: sn, code: code, password: normalizedPassword)
            )
            borrowPassword = normalizedPassword
            borrowRecords = try await repository.fetchBorrowRecords(password: normalizedPassword)
            hasLoadedBorrowRecords = true
            submitState = .success("续借申请已提交")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "续借失败")
        }
    }

    func clearSubmitState() {
        submitState = .idle
    }
}
