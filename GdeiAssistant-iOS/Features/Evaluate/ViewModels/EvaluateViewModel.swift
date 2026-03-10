import Foundation
import Combine

@MainActor
final class EvaluateViewModel: ObservableObject {
    @Published var submission = EvaluateSubmission(directSubmit: false)
    @Published var showConfirm = false
    @Published var submitState: SubmitState = .idle

    private let repository: any EvaluateRepository

    init(repository: any EvaluateRepository) {
        self.repository = repository
    }

    func requestSubmit() {
        showConfirm = true
    }

    func submit() async {
        showConfirm = false
        submitState = .submitting
        do {
            try await repository.submit(submission)
            submitState = .success("评教提交成功")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "评教提交失败")
        }
    }
}
