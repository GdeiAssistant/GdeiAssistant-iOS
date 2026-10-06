import Foundation
import Combine

@MainActor
final class DirectMessagePrivacyViewModel: ObservableObject {
    @Published var policy: DirectMessagePolicy = .mutual
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: any SocialRepository

    init(repository: any SocialRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            policy = try await repository.fetchPrivacy().dmPolicy
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.dmPolicy.loadFailed")
        }
    }

    func update(_ next: DirectMessagePolicy) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            policy = try await repository.updatePrivacy(next).dmPolicy
            successMessage = localizedString("social.dmPolicy.updateSuccess")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.dmPolicy.updateFailed")
        }
    }
}
