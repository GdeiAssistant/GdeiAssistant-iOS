import Foundation

enum GraduateExamRemoteMapper {
    nonisolated static func mapQuery(_ query: GraduateExamQuery) -> GraduateExamQueryRemoteDTO {
        GraduateExamQueryRemoteDTO(
            name: FormValidationSupport.trimmed(query.name),
            examNumber: FormValidationSupport.trimmed(query.examNumber),
            idNumber: FormValidationSupport.trimmed(query.idNumber)
        )
    }

    nonisolated static func mapScore(_ dto: GraduateExamScoreRemoteDTO) -> GraduateExamScore {
        GraduateExamScore(
            name: RemoteMapperSupport.firstNonEmpty(dto.name, "未命名考生"),
            signupNumber: RemoteMapperSupport.firstNonEmpty(dto.signUpNumber, "暂无"),
            examNumber: RemoteMapperSupport.firstNonEmpty(dto.examNumber, "暂无"),
            totalScore: RemoteMapperSupport.firstNonEmpty(dto.totalScore, "0"),
            politicsScore: RemoteMapperSupport.firstNonEmpty(dto.firstScore, "0"),
            foreignLanguageScore: RemoteMapperSupport.firstNonEmpty(dto.secondScore, "0"),
            businessOneScore: RemoteMapperSupport.firstNonEmpty(dto.thirdScore, "0"),
            businessTwoScore: RemoteMapperSupport.firstNonEmpty(dto.fourthScore, "0")
        )
    }
}
