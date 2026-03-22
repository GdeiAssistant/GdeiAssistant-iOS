import Foundation
import Combine

@MainActor
final class CETViewModel: ObservableObject {
    @Published var dashboard: CETDashboard?
    @Published var ticketNumber = ""
    @Published var candidateName = ""
    @Published var captchaCode = ""
    @Published var captchaImageBase64: String?
    @Published var isLoading = false
    @Published var isCaptchaLoading = false
    @Published var errorMessage: String?
    @Published var queryState: SubmitState = .idle

    private let repository: any CETRepository

    init(repository: any CETRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard dashboard == nil else { return }
        await refreshCaptcha()
    }

    func refreshCaptcha() async {
        isCaptchaLoading = true
        defer { isCaptchaLoading = false }

        do {
            captchaImageBase64 = try await repository.fetchCaptchaImageBase64()
        } catch {
            captchaImageBase64 = nil
        }
    }

    func queryScore() async {
        ticketNumber = FormValidationSupport.digitsOnly(ticketNumber, maxLength: 15)
        candidateName = FormValidationSupport.trimmed(candidateName)
        captchaCode = FormValidationSupport.trimmed(captchaCode)

        guard ticketNumber.count == 15 else {
            queryState = .failure(localizedString("cet.vm.ticketMustBe15"))
            return
        }
        guard FormValidationSupport.hasText(candidateName) else {
            queryState = .failure(localizedString("cet.vm.enterName"))
            return
        }
        guard FormValidationSupport.hasText(captchaCode) else {
            queryState = .failure(localizedString("cet.vm.enterCaptcha"))
            return
        }

        queryState = .submitting

        do {
            let dashboard = try await repository.queryScore(
                request: CETScoreQueryRequest(
                    ticketNumber: ticketNumber,
                    name: candidateName,
                    captchaCode: captchaCode
                )
            )
            self.dashboard = dashboard
            queryState = .success(localizedString("cet.vm.querySuccess"))
            captchaCode = ""
            await refreshCaptcha()
        } catch {
            queryState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("cet.vm.queryFailed"))
            await refreshCaptcha()
        }
    }

    func clearQueryState() {
        queryState = .idle
    }
}
