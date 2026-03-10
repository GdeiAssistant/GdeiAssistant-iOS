import Foundation

struct LibraryBook: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let availableCount: Int
    let location: String
}

struct LibraryBookDetail: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let summary: String
    let availableCount: Int
    let location: String
}

struct BorrowRecord: Codable, Identifiable, Hashable {
    let id: String
    let bookTitle: String
    let borrowDate: String
    let dueDate: String
    let status: String
    let renewable: Bool
    let sn: String?
    let code: String?
}

struct LibraryRenewRequest: Codable, Hashable {
    let sn: String
    let code: String
    let password: String
}
