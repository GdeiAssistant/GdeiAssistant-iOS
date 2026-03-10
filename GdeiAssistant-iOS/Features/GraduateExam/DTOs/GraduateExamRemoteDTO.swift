import Foundation

struct GraduateExamQueryRemoteDTO: Encodable {
    let name: String
    let examNumber: String
    let idNumber: String
}

struct GraduateExamScoreRemoteDTO: Decodable {
    let name: String?
    let signUpNumber: String?
    let examNumber: String?
    let totalScore: String?
    let firstScore: String?
    let secondScore: String?
    let thirdScore: String?
    let fourthScore: String?
}
