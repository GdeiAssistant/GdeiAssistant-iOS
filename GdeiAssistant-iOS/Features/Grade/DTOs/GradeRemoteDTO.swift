import Foundation

struct GradeQueryResultDTO: Decodable {
    let year: Int?
    let firstTermGPA: Double?
    let firstTermIGP: Double?
    let secondTermGPA: Double?
    let secondTermIGP: Double?
    let firstTermGradeList: [GradeEntryDTO]?
    let secondTermGradeList: [GradeEntryDTO]?
}

struct GradeEntryDTO: Decodable {
    let gradeYear: String?
    let gradeTerm: String?
    let gradeId: String?
    let gradeName: String?
    let gradeCredit: String?
    let gradeType: String?
    let gradeGpa: String?
    let gradeScore: String?
}
