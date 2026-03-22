import Foundation

@MainActor
final class MockLibraryRepository: LibraryRepository {
    private let validPasswords: Set<String> = ["library123", "123456"]
    private var renewedRecordIDs: Set<String> = []

    func searchBooks(keyword: String, page: Int) async throws -> [LibraryBook] {
        try await Task.sleep(nanoseconds: 260_000_000)
        return MockFactory.makeLibraryBooks(keyword: keyword)
    }

    func fetchBookDetail(bookID: String) async throws -> LibraryBookDetail {
        try await Task.sleep(nanoseconds: 220_000_000)
        return MockFactory.makeLibraryBookDetail(bookID: bookID)
    }

    func fetchBorrowRecords(password: String) async throws -> [BorrowRecord] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let normalizedPassword = FormValidationSupport.trimmed(password)
        guard !normalizedPassword.isEmpty else {
            throw NetworkError.server(code: 400, message: "请输入图书馆密码")
        }
        guard validPasswords.contains(normalizedPassword) else {
            throw NetworkError.server(code: 400, message: "模拟查询失败：图书馆密码不正确")
        }
        return MockFactory.makeBorrowRecords(renewedRecordIDs: renewedRecordIDs)
    }

    func renewBorrow(request: LibraryRenewRequest) async throws {
        try await Task.sleep(nanoseconds: 240_000_000)

        let password = FormValidationSupport.trimmed(request.password)
        guard !password.isEmpty else {
            throw NetworkError.server(code: 400, message: "请输入图书馆密码")
        }
        guard validPasswords.contains(password) else {
            throw NetworkError.server(code: 400, message: "模拟续借失败：图书馆密码不正确")
        }

        renewedRecordIDs.insert(request.sn)
        renewedRecordIDs.insert(request.code)
    }
}
