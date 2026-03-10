import Foundation

struct ProfileUpdateRequest: Hashable {
    let nickname: String
    let college: String
    let major: String
    let grade: String
    let bio: String
    let birthday: String
    let location: ProfileLocationSelection?
    let hometown: ProfileLocationSelection?
}
