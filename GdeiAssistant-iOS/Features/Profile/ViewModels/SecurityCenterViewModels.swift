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

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            records = try await repository.fetchLoginRecords()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("security.loginRecordFailed")
        }
    }
}
