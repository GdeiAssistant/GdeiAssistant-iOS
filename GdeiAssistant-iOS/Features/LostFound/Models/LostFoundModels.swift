import Foundation

enum LostFoundType: String, Codable, CaseIterable {
    case lost
    case found

    nonisolated var displayName: String {
        switch self {
        case .lost:
            return "寻物"
        case .found:
            return "招领"
        }
    }

    nonisolated var remoteValue: Int {
        switch self {
        case .lost:
            return 0
        case .found:
            return 1
        }
    }
}

enum LostFoundItemState: Int, Codable, Hashable {
    case active = 0
    case resolved = 1
    case systemDeleted = 2

    var title: String {
        switch self {
        case .active:
            return "寻主/寻物中"
        case .resolved:
            return "已找回"
        case .systemDeleted:
            return "系统删除"
        }
    }
}

struct LostFoundItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let type: LostFoundType
    let itemTypeID: Int
    let summary: String
    let location: String
    let createdAt: String
    let state: LostFoundItemState
    let previewImageURL: String?
}

struct LostFoundDetail: Codable, Identifiable, Hashable {
    var id: String { item.id }

    let item: LostFoundItem
    let description: String
    let contactHint: String
    let statusText: String
    let ownerUsername: String?
    let ownerNickname: String?
    let ownerAvatarURL: String?
    let imageURLs: [String]
}

struct LostFoundPersonalSummary: Codable, Hashable {
    let avatarURL: String?
    let nickname: String
    let introduction: String
    let lost: [LostFoundItem]
    let found: [LostFoundItem]
    let didFound: [LostFoundItem]
}

struct LostFoundDraft: Codable {
    let title: String
    let type: LostFoundType
    let itemTypeID: Int
    let summary: String
    let description: String
    let location: String
    let contactHint: String
    let qq: String?
    let wechat: String?
    let phone: String?
    let images: [UploadImageAsset]
}

struct LostFoundUpdateDraft: Codable {
    let title: String
    let type: LostFoundType
    let itemTypeID: Int
    let description: String
    let location: String
    let qq: String?
    let wechat: String?
    let phone: String?
}
