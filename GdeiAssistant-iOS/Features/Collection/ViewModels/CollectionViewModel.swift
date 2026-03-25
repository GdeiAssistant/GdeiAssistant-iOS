import Foundation
import Combine

@MainActor
final class CollectionViewModel: ObservableObject {
    @Published var keyword = ""
    @Published var borrowPassword = ""
    @Published var searchPage = CollectionSearchPage(items: [], sumPage: 0)
    @Published var selectedDetail: CollectionDetailInfo?
    @Published var borrowedBooks: [CollectionBorrowItem] = []
    @Published var isLoading = false
    @Published var isBorrowLoading = false
    @Published var isDetailLoading = false
    @Published var errorMessage: String?
    @Published var borrowMessage: String?
    @Published var hasLoadedBorrowedBooks = false
    @Published var submitState: SubmitState = .idle

    private let repository: any CollectionRepository

    init(repository: any CollectionRepository) {
        self.repository = repository
    }

    func search() async {
        let trimmed = FormValidationSupport.trimmed(keyword)
        guard !trimmed.isEmpty else {
            errorMessage = localizedString("collection.keywordEmpty")
            searchPage = CollectionSearchPage(items: [], sumPage: 0)
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            searchPage = try await repository.search(keyword: trimmed, page: 1)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("collection.searchFailed")
        }
    }

    func loadDetail(for item: CollectionSearchItem) async {
        isDetailLoading = true
        defer { isDetailLoading = false }
        do {
            selectedDetail = try await repository.fetchDetail(detailURL: item.detailURL)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("collection.detailFailed")
        }
    }

    func loadBorrowedBooks() async {
        let normalizedPassword = FormValidationSupport.trimmed(borrowPassword)
        guard !normalizedPassword.isEmpty else {
            borrowMessage = localizedString("collection.passwordEmpty")
            hasLoadedBorrowedBooks = false
            borrowedBooks = []
            return
        }
        isBorrowLoading = true
        borrowMessage = nil
        defer { isBorrowLoading = false }
        do {
            borrowedBooks = try await repository.fetchBorrowedBooks(password: normalizedPassword)
            borrowPassword = normalizedPassword
            hasLoadedBorrowedBooks = true
        } catch {
            hasLoadedBorrowedBooks = false
            borrowedBooks = []
            borrowMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("collection.borrowFailed")
        }
    }

    func renewBorrow(item: CollectionBorrowItem) async {
        let normalizedPassword = FormValidationSupport.trimmed(borrowPassword)
        guard !normalizedPassword.isEmpty else {
            submitState = .failure(localizedString("collection.passwordEmpty"))
            return
        }
        submitState = .submitting
        do {
            try await repository.renewBorrow(sn: item.sn, code: item.code, password: normalizedPassword)
            await loadBorrowedBooks()
            submitState = .success(localizedString("collection.renewSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("collection.renewFailed"))
        }
    }
}
