import Foundation
import Combine

@MainActor
final class CollectionViewModel: ObservableObject {
    @Published var keyword = ""
    @Published var searchPage = CollectionSearchPage(items: [], sumPage: 0)
    @Published var selectedDetail: CollectionDetailInfo?
    @Published var borrowedBooks: [CollectionBorrowItem] = []
    @Published var isLoading = false
    @Published var isBorrowLoading = false
    @Published var isDetailLoading = false
    @Published var errorMessage: String?
    @Published var borrowMessage: String?
    @Published var submitState: SubmitState = .idle

    private let repository: any CollectionRepository

    init(repository: any CollectionRepository) {
        self.repository = repository
    }

    func search() async {
        let trimmed = FormValidationSupport.trimmed(keyword)
        guard !trimmed.isEmpty else {
            errorMessage = "请输入检索关键词"
            searchPage = CollectionSearchPage(items: [], sumPage: 0)
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            searchPage = try await repository.search(keyword: trimmed, page: 1)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "馆藏检索失败"
        }
    }

    func loadDetail(for item: CollectionSearchItem) async {
        isDetailLoading = true
        defer { isDetailLoading = false }
        do {
            selectedDetail = try await repository.fetchDetail(detailURL: item.detailURL)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "馆藏详情加载失败"
        }
    }

    func loadBorrowedBooks(password: String?) async {
        isBorrowLoading = true
        borrowMessage = nil
        defer { isBorrowLoading = false }
        do {
            borrowedBooks = try await repository.fetchBorrowedBooks(password: password)
        } catch {
            borrowMessage = (error as? LocalizedError)?.errorDescription ?? "借阅信息加载失败"
        }
    }

    func renewBorrow(item: CollectionBorrowItem) async {
        submitState = .submitting
        do {
            try await repository.renewBorrow(sn: item.sn, code: item.code)
            await loadBorrowedBooks(password: nil)
            submitState = .success("已提交续借请求")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "续借失败")
        }
    }
}
