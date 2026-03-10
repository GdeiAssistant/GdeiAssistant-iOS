import Foundation

struct CETProfile: Codable, Hashable {
    let candidateName: String
    let schoolName: String
    let examLevel: String
    let admissionTicket: String
    let examDate: String
    let examVenue: String
}

struct CETScoreRecord: Codable, Identifiable, Hashable {
    let id: String
    let examSession: String
    let level: String
    let totalScore: Int
    let listeningScore: Int
    let readingScore: Int
    let writingScore: Int
    let speakingScore: Int?
    let passed: Bool
}

struct CETDashboard: Codable {
    let profile: CETProfile
    let scoreRecords: [CETScoreRecord]
}

struct CETScoreQueryRequest: Codable, Hashable {
    let ticketNumber: String
    let name: String
    let captchaCode: String
}
