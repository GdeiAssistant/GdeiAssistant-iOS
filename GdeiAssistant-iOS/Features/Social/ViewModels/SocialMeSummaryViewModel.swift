import Foundation
import Combine

@MainActor
final class SocialMeSummaryViewModel: ObservableObject {
    @Published private(set) var me: SocialUser?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: any SocialRepository

    init(repository: any SocialRepository) {
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
            me = try await repository.fetchMe()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.profile.loadFailed")
        }
    }
}
