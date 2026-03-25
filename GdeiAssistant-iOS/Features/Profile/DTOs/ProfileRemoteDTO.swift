import Foundation

struct UserProfileDTO: Decodable {
    let username: String
    let nickname: String?
    let avatar: String?
    let facultyCode: Int?
    let majorCode: String?
    let enrollment: String?
    let location: ProfileRemoteLocationValueDTO?
    let hometown: ProfileRemoteLocationValueDTO?
    let introduction: String?
    let birthday: String?
    let ipArea: String?
    let age: Int?
}

struct ProfileRemoteLocationValueDTO: Decodable {
    let regionCode: String?
    let stateCode: String?
    let cityCode: String?
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
}

struct ProfileLocationStateDTO: Decodable {
    let code: String?
    let children: [ProfileLocationCityDTO]?
}

struct ProfileLocationRegionDTO: Decodable {
    let code: String?
    let children: [ProfileLocationStateDTO]?
}

struct ProfileFacultyOptionDTO: Decodable {
    let code: Int?
    let majors: [String]?
}

struct ProfileOptionsDTO: Decodable {
    let faculties: [ProfileFacultyOptionDTO]?
    let marketplaceItemTypes: [Int]?
    let lostFoundItemTypes: [Int]?
    let lostFoundModes: [Int]?
}
