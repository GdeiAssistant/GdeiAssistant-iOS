import Foundation

enum CETRemoteMapper {
    nonisolated static func emptyDashboard() -> CETDashboard {
        CETDashboard(
            profile: CETProfile(
                candidateName: localizedString("cet.mapper.notSaved"),
                schoolName: localizedString("cet.mapper.defaultSchool"),
                examLevel: localizedString("cet.mapper.pendingQuery"),
                admissionTicket: localizedString("cet.mapper.ticketNotSaved"),
                examDate: localizedString("cet.mapper.captchaRequired"),
                examVenue: localizedString("cet.mapper.apiNotAvailable")
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
        let candidateName = RemoteMapperSupport.firstNonEmpty(numberDTO?.name, scoreDTO?.name, localizedString("cet.mapper.notSaved"))
        let admissionTicket = RemoteMapperSupport.firstNonEmpty(
            numberDTO.map { RemoteMapperSupport.text($0.number) },
            scoreDTO.map { RemoteMapperSupport.text($0.admissionCard) },
            localizedString("cet.mapper.ticketNotSaved")
        )

        let profile = CETProfile(
            candidateName: candidateName,
            schoolName: RemoteMapperSupport.firstNonEmpty(scoreDTO?.school, localizedString("cet.mapper.defaultSchool")),
            examLevel: RemoteMapperSupport.firstNonEmpty(scoreDTO?.type, localizedString("cet.mapper.pendingQuery")),
            admissionTicket: admissionTicket,
            examDate: scoreDTO == nil ? localizedString("cet.mapper.captchaRequired") : localizedString("cet.mapper.latestResult"),
            examVenue: localizedString("cet.mapper.apiNotAvailable")
        )

        let scoreRecords: [CETScoreRecord]
        if let scoreDTO {
            let totalScore = RemoteMapperSupport.int(scoreDTO.totalScore)
            scoreRecords = [
                CETScoreRecord(
                    id: admissionTicket,
                    examSession: localizedString("cet.mapper.latestQuery"),
                    level: RemoteMapperSupport.firstNonEmpty(scoreDTO.type, localizedString("cet.mapper.unknownLevel")),
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
