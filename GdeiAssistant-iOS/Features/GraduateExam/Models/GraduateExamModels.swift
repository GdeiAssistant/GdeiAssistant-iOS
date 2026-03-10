import Foundation

struct GraduateExamQuery: Equatable {
    var name = ""
    var examNumber = ""
    var idNumber = ""
}

struct GraduateExamScore: Equatable {
    let name: String
    let signupNumber: String
    let examNumber: String
    let totalScore: String
    let politicsScore: String
    let foreignLanguageScore: String
    let businessOneScore: String
    let businessTwoScore: String
}
