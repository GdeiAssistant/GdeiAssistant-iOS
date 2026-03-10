import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let nickname: String
    let avatarURL: String
    let college: String
    let major: String
    let grade: String
    let bio: String
    let birthday: String
    let location: String
    let hometown: String
    let ipArea: String

    init(
        id: String,
        username: String,
        nickname: String,
        avatarURL: String,
        college: String,
        major: String,
        grade: String,
        bio: String,
        birthday: String = "",
        location: String = "",
        hometown: String = "",
        ipArea: String = ""
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.college = college
        self.major = major
        self.grade = grade
        self.bio = bio
        self.birthday = birthday
        self.location = location
        self.hometown = hometown
        self.ipArea = ipArea
    }
}
