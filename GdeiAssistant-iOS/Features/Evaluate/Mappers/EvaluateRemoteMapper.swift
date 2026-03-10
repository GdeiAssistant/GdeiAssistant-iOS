import Foundation

enum EvaluateRemoteMapper {
    nonisolated static func mapSubmitDTO(_ submission: EvaluateSubmission) -> EvaluateSubmitRemoteDTO {
        EvaluateSubmitRemoteDTO(directSubmit: submission.directSubmit)
    }
}
