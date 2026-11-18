import Foundation

@MainActor
protocol CETRepository {
    func fetchCaptchaImageBase64() async throws -> String
    func queryScore(request: CETScoreQueryRequest) async throws -> CETDashboard
}
