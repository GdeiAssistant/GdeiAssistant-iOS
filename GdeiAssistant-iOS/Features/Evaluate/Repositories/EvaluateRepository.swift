import Foundation

@MainActor
protocol EvaluateRepository {
    func submit(_ submission: EvaluateSubmission) async throws
}
