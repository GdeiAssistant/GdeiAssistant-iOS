import Foundation

enum CETRemoteMapper {
    nonisolated static func emptyDashboard() -> CETDashboard {
        CETDashboard(
            profile: CETProfile(
                candidateName: "未保存",
                schoolName: "广东第二师范学院",
                examLevel: "待查询",
                admissionTicket: "未保存准考证号",
                examDate: "需验证码后查询",
                examVenue: "后端接口暂未提供"
            ),
            scoreRecords: []
        )
    }

    nonisolated static func mapScoreQueryRequest(_ request: CETScoreQueryRequest) -> CETScoreQueryRemoteDTO {
        CETScoreQueryRemoteDTO(
            ticketNumber: FormValidationSupport.trimmed(request.ticketNumber),
            name: FormValidationSupport.trimmed(request.name),
            checkcode: FormValidationSupport.trimmed(request.captchaCode)
        )
    }

    nonisolated static func mapScoreQueryItems(_ dto: CETScoreQueryRemoteDTO) -> [URLQueryItem] {
        [
            URLQueryItem(name: "ticketNumber", value: dto.ticketNumber),
            URLQueryItem(name: "name", value: dto.name),
            URLQueryItem(name: "checkcode", value: dto.checkcode)
        ]
    }

    nonisolated static func mapDashboard(numberDTO: CETNumberDTO?, scoreDTO: CETScoreDTO?) -> CETDashboard {
        let candidateName = RemoteMapperSupport.firstNonEmpty(numberDTO?.name, scoreDTO?.name, "未保存")
        let admissionTicket = RemoteMapperSupport.firstNonEmpty(
            numberDTO.map { RemoteMapperSupport.text($0.number) },
            scoreDTO.map { RemoteMapperSupport.text($0.admissionCard) },
            "未保存准考证号"
        )

        let profile = CETProfile(
            candidateName: candidateName,
            schoolName: RemoteMapperSupport.firstNonEmpty(scoreDTO?.school, "广东第二师范学院"),
            examLevel: RemoteMapperSupport.firstNonEmpty(scoreDTO?.type, "待查询"),
            admissionTicket: admissionTicket,
            examDate: scoreDTO == nil ? "需验证码后查询" : "最近一次查询结果",
            examVenue: "后端接口暂未提供"
        )

        let scoreRecords: [CETScoreRecord]
        if let scoreDTO {
            let totalScore = RemoteMapperSupport.int(scoreDTO.totalScore)
            scoreRecords = [
                CETScoreRecord(
                    id: admissionTicket,
                    examSession: "最近一次查询",
                    level: RemoteMapperSupport.firstNonEmpty(scoreDTO.type, "未知级别"),
                    totalScore: totalScore,
                    listeningScore: RemoteMapperSupport.int(scoreDTO.listeningScore),
                    readingScore: RemoteMapperSupport.int(scoreDTO.readingScore),
                    writingScore: RemoteMapperSupport.int(scoreDTO.writingAndTranslatingScore),
                    speakingScore: nil,
                    passed: totalScore >= 425
                )
            ]
        } else {
            scoreRecords = []
        }

        return CETDashboard(profile: profile, scoreRecords: scoreRecords)
    }

    nonisolated static func mapDashboard(
        request: CETScoreQueryRequest,
        scoreDTO: CETScoreDTO
    ) -> CETDashboard {
        mapDashboard(
            numberDTO: CETNumberDTO(number: RemoteFlexibleString(request.ticketNumber), name: request.name),
            scoreDTO: scoreDTO
        )
    }
}
