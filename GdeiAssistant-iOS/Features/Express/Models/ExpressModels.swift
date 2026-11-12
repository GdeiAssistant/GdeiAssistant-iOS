import Foundation

enum ExpressGender: Int, CaseIterable, Identifiable, Codable {
    case male = 0
    case female = 1
    case secret = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .male:
            return localizedString("express.gender.male")
        case .female:
            return localizedString("express.gender.female")
        case .secret:
            return localizedString("express.gender.secret")
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

extension ExpressPost {
    /// A copy with only the given counters changed. Both the mock repository and the view
    /// model apply the same optimistic updates, so adding a field must not require editing
    /// six full memberwise constructions.
    func with(
        likeCount: Int? = nil,
        commentCount: Int? = nil,
        guessCount: Int? = nil,
        correctGuessCount: Int? = nil,
        isLiked: Bool? = nil
    ) -> ExpressPost {
        ExpressPost(
            id: id,
            nickname: nickname,
            targetName: targetName,
            contentPreview: contentPreview,
            publishTime: publishTime,
            likeCount: likeCount ?? self.likeCount,
            commentCount: commentCount ?? self.commentCount,
            guessCount: guessCount ?? self.guessCount,
            correctGuessCount: correctGuessCount ?? self.correctGuessCount,
            isLiked: isLiked ?? self.isLiked,
            canGuess: canGuess,
            selfGender: selfGender,
            targetGender: targetGender
        )
    }
}
