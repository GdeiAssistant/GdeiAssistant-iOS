import Foundation

@MainActor
final class MockEvaluateRepository: EvaluateRepository {
    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    func submit(_ submission: EvaluateSubmission) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        _ = submission
    }
}
