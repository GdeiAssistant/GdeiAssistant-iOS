import Foundation

enum ExpressGender: Int, CaseIterable, Identifiable, Codable {
    case male = 0
    case female = 1
    case secret = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .male:
            return "男"
        case .female:
            return "女"
        case .secret:
            return "其他或保密"
        }
    }
}

struct ExpressPost: Codable, Identifiable, Hashable {
    let id: String
    let nickname: String
    let targetName: String
    let contentPreview: String
    let publishTime: String
    let likeCount: Int
    let commentCount: Int
    let guessCount: Int
    let correctGuessCount: Int
    let isLiked: Bool
    let canGuess: Bool
    let selfGender: ExpressGender
    let targetGender: ExpressGender
}

struct ExpressPostDetail: Codable, Identifiable, Hashable {
    var id: String { post.id }

    let post: ExpressPost
    let realName: String?
    let content: String
}

struct ExpressCommentItem: Codable, Identifiable, Hashable {
    let id: String
    let authorName: String
    let content: String
    let publishTime: String
}

struct ExpressDraft: Codable {
    let nickname: String
    let realName: String?
    let selfGender: ExpressGender
    let targetName: String
    let content: String
    let targetGender: ExpressGender
}
