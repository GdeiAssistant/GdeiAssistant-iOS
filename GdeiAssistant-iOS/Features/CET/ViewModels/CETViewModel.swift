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
            queryState = .failure("准考证号必须为15位数字")
            return
        }
        guard FormValidationSupport.hasText(candidateName) else {
            queryState = .failure("请输入姓名")
            return
        }
        guard FormValidationSupport.hasText(captchaCode) else {
            queryState = .failure("请输入验证码")
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
            queryState = .success("成绩查询完成")
            captchaCode = ""
            await refreshCaptcha()
        } catch {
            queryState = .failure((error as? LocalizedError)?.errorDescription ?? "查询失败")
            await refreshCaptcha()
        }
    }

    func clearQueryState() {
        queryState = .idle
    }
}
