import Foundation

@MainActor
final class MockCollectionRepository: CollectionRepository {
    private var borrowedBooks: [CollectionBorrowItem] = [
        CollectionBorrowItem(id: "c_borrow_1", sn: "sn_1001", code: "code_1001", title: "iOS 架构设计实践", author: "王磊", borrowDate: "2026-03-01", returnDate: "2026-03-22", renewCount: 0),
        CollectionBorrowItem(id: "c_borrow_2", sn: "sn_1002", code: "code_1002", title: "数据库系统概论", author: "陈小华", borrowDate: "2026-02-24", returnDate: "2026-03-17", renewCount: 1)
    ]

    func search(keyword: String, page: Int) async throws -> CollectionSearchPage {
        try await Task.sleep(nanoseconds: 150_000_000)
        let source = [
            CollectionSearchItem(id: "c_1", title: "SwiftUI 界面开发", author: "李明", publisher: "人民邮电出版社", detailURL: "detail_swiftui"),
            CollectionSearchItem(id: "c_2", title: "操作系统概念", author: "Abraham Silberschatz", publisher: "机械工业出版社", detailURL: "detail_os"),
            CollectionSearchItem(id: "c_3", title: "大学英语六级真题精讲", author: "刘洋", publisher: "外语教学出版社", detailURL: "detail_cet"),
            CollectionSearchItem(id: "c_4", title: "研究生入学考试数学复习全书", author: "张宇", publisher: "高等教育出版社", detailURL: "detail_kaoyan")
        ]
        let trimmed = FormValidationSupport.trimmed(keyword)
        let filtered = trimmed.isEmpty ? source : source.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.author.localizedCaseInsensitiveContains(trimmed)
        }
        _ = page
        return CollectionSearchPage(items: filtered, sumPage: 1)
    }

    func fetchDetail(detailURL: String) async throws -> CollectionDetailInfo {
        try await Task.sleep(nanoseconds: 120_000_000)
        let title = detailURL == "detail_os" ? "操作系统概念" : "SwiftUI 界面开发"
        return CollectionDetailInfo(
            id: detailURL,
            title: title,
            author: detailURL == "detail_os" ? "Abraham Silberschatz" : "李明",
            principal: "信息工程学院图书馆编目",
            publisher: detailURL == "detail_os" ? "机械工业出版社" : "人民邮电出版社",
            price: "68.00",
            physicalDescription: "16 开，附录含实验案例与索引。",
            subjectTheme: "移动开发 / 计算机基础",
            classification: "TP312.8",
            distributions: [
                CollectionDistributionItem(id: "barcode_1", location: "北校区图书馆 3 楼 A 区", callNumber: "TP312.8/S12", barcode: "B1002381", state: "在馆"),
                CollectionDistributionItem(id: "barcode_2", location: "南校区图书馆 2 楼借阅区", callNumber: "TP312.8/S12", barcode: "B1002382", state: "可借"),
            ]
        )
    }

    func fetchBorrowedBooks(password: String) async throws -> [CollectionBorrowItem] {
        try await Task.sleep(nanoseconds: 140_000_000)
        let normalizedPassword = FormValidationSupport.trimmed(password)
        if normalizedPassword != "123456" && normalizedPassword != "library123" {
            throw NetworkError.server(code: 400, message: localizedString("collection.invalidPassword"))
        }
        return borrowedBooks
    }

    func renewBorrow(sn: String, code: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
        let normalizedPassword = FormValidationSupport.trimmed(password)
        if normalizedPassword != "123456" && normalizedPassword != "library123" {
            throw NetworkError.server(code: 400, message: localizedString("collection.invalidPassword"))
        }
        guard let index = borrowedBooks.firstIndex(where: { $0.sn == sn && $0.code == code }) else {
            throw NetworkError.server(code: 404, message: localizedString("collection.renewNotFound"))
        }
        let current = borrowedBooks[index]
        borrowedBooks[index] = CollectionBorrowItem(
            id: current.id,
            sn: current.sn,
            code: current.code,
            title: current.title,
            author: current.author,
            borrowDate: current.borrowDate,
            returnDate: "2026-04-05",
            renewCount: current.renewCount + 1
        )
    }
}
