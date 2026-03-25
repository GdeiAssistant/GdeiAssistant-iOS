import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let nickname: String
    let avatarURL: String
    let college: String
    let collegeCode: Int?
    let major: String
    let majorCode: String?
    let grade: String
    let bio: String
    let birthday: String
    let location: String
    let locationSelection: ProfileLocationSelection?
    let hometown: String
    let hometownSelection: ProfileLocationSelection?
    let ipArea: String

    init(
        id: String,
        username: String,
        nickname: String,
        avatarURL: String,
        college: String,
        collegeCode: Int? = nil,
        major: String,
        majorCode: String? = nil,
        grade: String,
        bio: String,
        birthday: String = "",
        location: String = "",
        locationSelection: ProfileLocationSelection? = nil,
        hometown: String = "",
        hometownSelection: ProfileLocationSelection? = nil,
        ipArea: String = ""
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.college = college
        self.collegeCode = collegeCode
        self.major = major
        self.majorCode = majorCode
        self.grade = grade
        self.bio = bio
        self.birthday = birthday
        self.location = location
        self.locationSelection = locationSelection
        self.hometown = hometown
        self.hometownSelection = hometownSelection
        self.ipArea = ipArea
    }
}
