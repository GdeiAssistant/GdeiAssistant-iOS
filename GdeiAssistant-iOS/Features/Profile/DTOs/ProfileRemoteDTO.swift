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

struct ProfilePatchDTO: Encodable {
    let nickname: String
    let faculty: Int
    let major: String?
    let enrollment: Int?
    let introduction: String
    let birthday: BirthdayUpdateDTO?
    let location: LocationUpdateDTO?
    let hometown: LocationUpdateDTO?

    enum CodingKeys: String, CodingKey {
        case nickname
        case faculty
        case major
        case enrollment
        case introduction
        case birthday
        case location
        case hometown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(faculty, forKey: .faculty)
        try container.encode(major, forKey: .major)
        try container.encode(enrollment, forKey: .enrollment)
        try container.encode(introduction, forKey: .introduction)
        try container.encode(birthday, forKey: .birthday)
        try container.encode(location, forKey: .location)
        try container.encode(hometown, forKey: .hometown)
    }
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

    enum CodingKeys: String, CodingKey {
        case region
        case state
        case city
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(region, forKey: .region)
        try container.encode(state, forKey: .state)
        try container.encode(city, forKey: .city)
    }
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
