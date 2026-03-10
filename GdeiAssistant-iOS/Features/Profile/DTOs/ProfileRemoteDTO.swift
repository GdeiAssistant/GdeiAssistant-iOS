import Foundation

struct UserProfileDTO: Decodable {
    let username: String
    let nickname: String?
    let avatar: String?
    let faculty: String?
    let major: String?
    let enrollment: String?
    let location: String?
    let hometown: String?
    let introduction: String?
    let birthday: String?
    let ipArea: String?
    let age: Int?
}

struct NicknameUpdateDTO: Encodable {
    let nickname: String
}

struct FacultyUpdateDTO: Encodable {
    let faculty: Int
}

struct MajorUpdateDTO: Encodable {
    let major: String
}

struct EnrollmentUpdateDTO: Encodable {
    let year: Int?
}

struct IntroductionUpdateDTO: Encodable {
    let introduction: String
}

struct BirthdayUpdateDTO: Encodable {
    let year: Int?
    let month: Int?
    let date: Int?
}

struct LocationUpdateDTO: Encodable {
    let region: String
    let state: String?
    let city: String?
}

struct ProfileLocationCityDTO: Decodable {
    let code: String?
    let name: String?
    let aliasesName: String?
}

struct ProfileLocationStateDTO: Decodable {
    let code: String?
    let name: String?
    let aliasesName: String?
    let cityMap: [String: ProfileLocationCityDTO]?
}

struct ProfileLocationRegionDTO: Decodable {
    let code: String?
    let name: String?
    let aliasesName: String?
    let stateMap: [String: ProfileLocationStateDTO]?
}
