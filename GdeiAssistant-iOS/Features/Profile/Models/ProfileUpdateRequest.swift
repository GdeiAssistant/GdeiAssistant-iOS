import Foundation

struct ProfileUpdateRequest: Hashable {
    let nickname: String
    let facultyCode: Int
    let majorCode: String?
    let enrollment: Int?
    let bio: String
    let birthday: String
    let location: ProfileLocationSelection?
    let hometown: ProfileLocationSelection?
}
