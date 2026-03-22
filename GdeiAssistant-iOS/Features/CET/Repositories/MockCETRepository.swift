import Foundation

@MainActor
final class MockCETRepository: CETRepository {
    func fetchCaptchaImageBase64() async throws -> String {
        try await Task.sleep(nanoseconds: 120_000_000)
        return MockSeedData.cetCaptchaBase64
    }

    func queryScore(request: CETScoreQueryRequest) async throws -> CETDashboard {
        try await Task.sleep(nanoseconds: 260_000_000)

        let code = FormValidationSupport.trimmed(request.captchaCode).lowercased()
        guard code == "gd26" || code == "1234" else {
            throw NetworkError.server(code: 400, message: localizedString("mock.cet.captchaError"))
        }

        return MockFactory.makeCETDashboard(
            ticketNumber: FormValidationSupport.trimmed(request.ticketNumber),
            candidateName: FormValidationSupport.trimmed(request.name)
        )
    }
}
