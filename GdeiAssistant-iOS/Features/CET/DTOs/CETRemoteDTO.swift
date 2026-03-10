import Foundation

struct CETNumberDTO: Decodable {
    let number: RemoteFlexibleString?
    let name: String?
}

struct CETScoreDTO: Decodable {
    let name: String?
    let school: String?
    let type: String?
    let admissionCard: RemoteFlexibleString?
    let totalScore: RemoteFlexibleString?
    let listeningScore: RemoteFlexibleString?
    let readingScore: RemoteFlexibleString?
    let writingAndTranslatingScore: RemoteFlexibleString?
}

struct CETScoreQueryRemoteDTO {
    let ticketNumber: String
    let name: String
    let checkcode: String
}
