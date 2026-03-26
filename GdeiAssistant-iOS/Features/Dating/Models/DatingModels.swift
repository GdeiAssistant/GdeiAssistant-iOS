import Foundation

enum DatingArea: Int, CaseIterable, Identifiable, Codable {
    case girl = 0
    case boy = 1

    var id: Int { rawValue }

    nonisolated var title: String {
        switch self {
        case .girl:
            return localizedString("dating.area.girl")
        case .boy:
            return localizedString("dating.area.boy")
        }
    }
}

enum DatingPickStatus: Int, Codable, Hashable {
    case pending = 0
    case accepted = 1
    case rejected = -1

    nonisolated var title: String {
        switch self {
        case .pending:
            return localizedString("dating.pickStatus.pending")
        case .accepted:
            return localizedString("dating.pickStatus.accepted")
        case .rejected:
            return localizedString("dating.pickStatus.rejected")
        }
    }
}

enum DatingCenterTab: String, CaseIterable, Identifiable, Codable, Hashable {
    case received
    case sent
    case posts

    var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .received:
            return localizedString("dating.center.received")
        case .sent:
            return localizedString("dating.center.sent")
        case .posts:
            return localizedString("dating.center.posts")
        }
    }
}

struct DatingTag: Codable, Identifiable, Hashable {
    let id: String
    let title: String
}

struct DatingProfile: Codable, Identifiable, Hashable {
    let id: String
    let nickname: String
    let headline: String
    let college: String
    let major: String
    let grade: String
    let tags: [DatingTag]
    let bio: String
    let imageURL: String?
    let hometown: String
    let qq: String?
    let wechat: String?
    let isContactVisible: Bool
    let area: DatingArea

    nonisolated init(
        id: String,
        nickname: String,
        headline: String,
        college: String,
        major: String,
        grade: String,
        tags: [DatingTag],
        bio: String,
        imageURL: String? = nil,
        hometown: String = localizedString("dating.fallback.hometown"),
        qq: String? = nil,
        wechat: String? = nil,
        isContactVisible: Bool = false,
        area: DatingArea = .girl
    ) {
        self.id = id
        self.nickname = nickname
        self.headline = headline
        self.college = college
        self.major = major
        self.grade = grade
        self.tags = tags
        self.bio = bio
        self.imageURL = imageURL
        self.hometown = hometown
        self.qq = qq
        self.wechat = wechat
        self.isContactVisible = isContactVisible
        self.area = area
    }
}

struct DatingProfileDetail: Codable, Identifiable, Hashable {
    var id: String { profile.id }

    let profile: DatingProfile
    let isPickNotAvailable: Bool
}

struct DatingFilter: Codable, Hashable {
    let area: DatingArea

    init(area: DatingArea = .girl) {
        self.area = area
    }
}

struct DatingPublishDraft: Codable {
    let nickname: String
    let grade: Int
    let area: DatingArea
    let faculty: String
    let hometown: String
    let qq: String?
    let wechat: String?
    let content: String
    let image: UploadImageAsset?
}

struct DatingReceivedPick: Codable, Identifiable, Hashable {
    let id: String
    let senderName: String
    let content: String
    let time: String
    let status: DatingPickStatus
    let avatarURL: String?
}

struct DatingSentPick: Codable, Identifiable, Hashable {
    let id: String
    let targetName: String
    let content: String
    let status: DatingPickStatus
    let targetQq: String?
    let targetWechat: String?
    let targetAvatarURL: String?
}

struct DatingMyPost: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let imageURL: String?
    let publishTime: String
    let grade: String
    let faculty: String
    let hometown: String
    let area: DatingArea
    let state: Int
}
