import Foundation

struct SecretPost: Codable, Identifiable, Hashable {
    let id: String
    let username: String
    let themeID: Int
    let title: String
    let summary: String
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let type: Int
    let timer: Int
    let state: Int
    let voiceURL: String?

    var isVoice: Bool { type != 0 }

    var timerText: String? {
        timer == 1 ? "24 小时后自动删除" : nil
    }

    var stateText: String {
        switch state {
        case 1:
            return "定时删除"
        case 2:
            return "管理员删除"
        default:
            return "已发布"
        }
    }
}

struct SecretPostDetail: Codable, Identifiable, Hashable {
    var id: String { post.id }

    let post: SecretPost
    let content: String
    let comments: [SecretComment]
}

enum SecretDraftMode: Int, Codable {
    case text = 0
    case voice = 1
}

struct SecretVoiceDraft: Codable, Hashable {
    let fileData: Data
    let fileName: String
    let mimeType: String
}

struct SecretDraft: Codable {
    let title: String
    let content: String?
    let themeID: Int
    let timerEnabled: Bool
    let mode: SecretDraftMode
    let voice: SecretVoiceDraft?
}

struct SecretComment: Codable, Identifiable, Hashable {
    let id: String
    let authorName: String
    let content: String
    let createdAt: String
    let avatarTheme: Int
}
