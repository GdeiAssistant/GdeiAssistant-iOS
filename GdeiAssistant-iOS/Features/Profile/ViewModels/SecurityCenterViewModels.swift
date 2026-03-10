import Foundation
import Combine

@MainActor
final class LoginRecordViewModel: ObservableObject {
    @Published var records: [LoginRecordItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            records = try await repository.fetchLoginRecords()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载登录记录失败"
        }
    }
}
