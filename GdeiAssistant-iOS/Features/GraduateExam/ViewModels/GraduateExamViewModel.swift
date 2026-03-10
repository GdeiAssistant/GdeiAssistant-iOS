import Foundation
import Combine

@MainActor
final class GraduateExamViewModel: ObservableObject {
    @Published var query = GraduateExamQuery()
    @Published var score: GraduateExamScore?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any GraduateExamRepository

    init(repository: any GraduateExamRepository) {
        self.repository = repository
    }

    func submit() async {
        guard FormValidationSupport.hasText(query.name), FormValidationSupport.hasText(query.examNumber), FormValidationSupport.hasText(query.idNumber) else {
            errorMessage = "请完整填写查询信息"
            score = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            score = try await repository.queryScore(query)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "考研成绩查询失败"
            score = nil
        }
    }
}
