import Foundation

struct UserProfileDTO: Decodable {
    let username: String
    let nickname: String?
    let avatar: String?
    let faculty: ProfileValueLabelIntDTO?
    let major: ProfileValueLabelStringDTO?
    let enrollment: String?
    let location: ProfileRemoteLocationValueDTO?
    let hometown: ProfileRemoteLocationValueDTO?
    let introduction: String?
    let birthday: String?
    let ipArea: String?
    let age: Int?
}

struct ProfileValueLabelIntDTO: Decodable {
    let code: Int?
    let label: String?
}

struct ProfileValueLabelStringDTO: Decodable {
    let code: String?
    let label: String?
}

struct ProfileRemoteLocationValueDTO: Decodable {
    let region: String?
    let state: String?
    let city: String?
    let displayName: String?
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

struct ProfileDictionaryOptionDTO: Decodable {
    let code: Int?
    let label: String?
}

struct ProfileFacultyOptionDTO: Decodable {
    let code: Int?
    let label: String?
    let majors: [ProfileMajorOptionDTO]?
}

struct ProfileMajorOptionDTO: Decodable {
    let code: String?
    let label: String?
}

struct ProfileOptionsDTO: Decodable {
    let faculties: [ProfileFacultyOptionDTO]?
    let marketplaceItemTypes: [ProfileDictionaryOptionDTO]?
    let lostFoundItemTypes: [ProfileDictionaryOptionDTO]?
    let lostFoundModes: [ProfileDictionaryOptionDTO]?
}
