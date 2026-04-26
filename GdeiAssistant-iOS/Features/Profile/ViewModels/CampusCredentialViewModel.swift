import Foundation
import Combine

@MainActor
final class CampusCredentialViewModel: ObservableObject {
    @Published var status = CampusCredentialStatus.empty
    @Published var isLoading = false
    @Published var isActionRunning = false
    @Published var noticeMessage: String?
    @Published var errorMessage: String?

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    var canRunAction: Bool {
        !isLoading && !isActionRunning
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            status = try await repository.fetchCampusCredentialStatus()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("campusCredential.loadFailed")
            noticeMessage = errorMessage
        }
    }

    func revokeConsent() async {
        await performAction(
            action: { try await repository.revokeCampusCredentialConsent() },
            successMessage: localizedString("campusCredential.revokeSuccess")
        )
    }

    func deleteCredential() async {
        await performAction(
            action: { try await repository.deleteCampusCredential() },
            successMessage: localizedString("campusCredential.deleteSuccess")
        )
    }

    func setQuickAuthEnabled(_ enabled: Bool) async {
        await performAction(
            action: { try await repository.setQuickAuthEnabled(enabled) },
            successMessage: enabled
                ? localizedString("campusCredential.quickAuthEnabled")
                : localizedString("campusCredential.quickAuthDisabled")
        )
    }

    private func performAction(
        action: () async throws -> CampusCredentialStatus,
        successMessage: String
    ) async {
        guard canRunAction else { return }
        isActionRunning = true
        errorMessage = nil
        defer { isActionRunning = false }

        do {
            status = try await action()
            noticeMessage = successMessage
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? localizedString("campusCredential.actionFailed")
            errorMessage = message
            noticeMessage = message
        }
    }
}
