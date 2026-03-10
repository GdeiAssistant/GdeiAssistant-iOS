import Foundation

enum LostFoundRemoteMapper {
    nonisolated static let itemTypes = ["手机", "校园卡", "身份证", "银行卡", "书", "钥匙", "包包", "衣帽", "校园代步", "运动健身", "数码配件", "其他"]
    nonisolated static let stateTypes = ["寻主/寻物中", "确认寻回", "系统删除"]

    nonisolated static func mapItems(lostItems: [LostFoundItemDTO], foundItems: [LostFoundItemDTO]) -> [LostFoundItem] {
        let mappedLost = lostItems
            .filter { mapState($0.state) == .active }
            .map { mapItem($0, fallbackType: .lost) }
        let mappedFound = foundItems
            .filter { mapState($0.state) == .active }
            .map { mapItem($0, fallbackType: .found) }

        return (mappedLost + mappedFound)
            .sorted { $0.createdAt > $1.createdAt }
    }

    nonisolated static func mapPublishDTO(_ draft: LostFoundDraft) -> LostFoundPublishRemoteDTO {
        LostFoundPublishRemoteDTO(
            name: draft.title,
            description: draft.description,
            location: draft.location,
            itemType: draft.itemTypeID,
            lostType: draft.type.remoteValue,
            qq: draft.qq,
            wechat: draft.wechat,
            phone: draft.phone
        )
    }

    nonisolated static func mapUpdateDTO(_ draft: LostFoundUpdateDraft) -> LostFoundPublishRemoteDTO {
        LostFoundPublishRemoteDTO(
            name: draft.title,
            description: draft.description,
            location: draft.location,
            itemType: draft.itemTypeID,
            lostType: draft.type.remoteValue,
            qq: draft.qq,
            wechat: draft.wechat,
            phone: draft.phone
        )
    }

    nonisolated static func mapPublishFields(_ dto: LostFoundPublishRemoteDTO) -> [FormFieldValue] {
        var fields = [
            FormFieldValue(name: "name", value: dto.name),
            FormFieldValue(name: "description", value: dto.description),
            FormFieldValue(name: "location", value: dto.location),
            FormFieldValue(name: "itemType", value: String(dto.itemType)),
            FormFieldValue(name: "lostType", value: String(dto.lostType))
        ]

        if let qq = dto.qq, !qq.isEmpty {
            fields.append(FormFieldValue(name: "qq", value: qq))
        }
        if let wechat = dto.wechat, !wechat.isEmpty {
            fields.append(FormFieldValue(name: "wechat", value: wechat))
        }
        if let phone = dto.phone, !phone.isEmpty {
            fields.append(FormFieldValue(name: "phone", value: phone))
        }

        return fields
    }

    nonisolated static func mapPublishFiles(_ draft: LostFoundDraft) -> [MultipartFormFile] {
        draft.images.enumerated().map { index, image in
            MultipartFormFile(
                name: "image\(index + 1)",
                fileName: image.fileName,
                mimeType: image.mimeType,
                data: image.data
            )
        }
    }

    nonisolated static func displayName(forItemType itemTypeID: Int) -> String {
        displayName(in: itemTypes, index: itemTypeID, fallback: "其他")
    }

    nonisolated static func mapDetail(_ dto: LostFoundDetailDTO) throws -> LostFoundDetail {
        guard let itemDTO = dto.item else {
            throw NetworkError.noData
        }

        let item = mapItem(itemDTO, fallbackType: (itemDTO.lostType ?? 0) == 0 ? .lost : .found)
        let statusText = displayName(in: stateTypes, index: itemDTO.state, fallback: "状态未知")
        let contactHint = [
            itemDTO.qq.flatMap { $0.isEmpty ? nil : "QQ：\($0)" },
            itemDTO.wechat.flatMap { $0.isEmpty ? nil : "微信：\($0)" },
            itemDTO.phone.flatMap { $0.isEmpty ? nil : "手机号：\($0)" }
        ].compactMap { $0 }.joined(separator: " / ")

        return LostFoundDetail(
            item: item,
            description: RemoteMapperSupport.firstNonEmpty(itemDTO.description, "暂无详细描述"),
            contactHint: contactHint.isEmpty ? "发布者暂未公开联系方式" : contactHint,
            statusText: statusText,
            ownerUsername: dto.profile?.username ?? itemDTO.username,
            ownerNickname: RemoteMapperSupport.sanitizedText(dto.profile?.nickname),
            ownerAvatarURL: RemoteMapperSupport.sanitizedText(dto.profile?.avatarURL),
            imageURLs: RemoteMapperSupport.sanitizedTextList(itemDTO.pictureURL)
        )
    }

    nonisolated static func mapPersonalSummary(_ dto: LostFoundPersonalSummaryDTO, profile: UserProfileDTO) -> LostFoundPersonalSummary {
        LostFoundPersonalSummary(
            avatarURL: RemoteMapperSupport.sanitizedText(profile.avatar),
            nickname: RemoteMapperSupport.firstNonEmpty(profile.nickname, profile.username, "失物招领用户"),
            introduction: RemoteMapperSupport.firstNonEmpty(profile.introduction, "这个人很懒，什么都没写_(:3 」∠)_"),
            lost: (dto.lost ?? []).map { mapItem($0, fallbackType: .lost) },
            found: (dto.found ?? []).map { mapItem($0, fallbackType: .found) },
            didFound: (dto.didfound ?? []).map { mapItem($0, fallbackType: ($0.lostType ?? 0) == 0 ? .lost : .found) }
        )
    }

    nonisolated private static func mapItem(_ dto: LostFoundItemDTO, fallbackType: LostFoundType) -> LostFoundItem {
        LostFoundItem(
            id: String(dto.id ?? Int.random(in: 1...999_999)),
            title: RemoteMapperSupport.firstNonEmpty(dto.name, "未命名物品"),
            type: fallbackType,
            itemTypeID: dto.itemType ?? 0,
            summary: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(dto.description, "暂无描述"), limit: 56),
            location: RemoteMapperSupport.firstNonEmpty(dto.location, displayName(in: itemTypes, index: dto.itemType, fallback: "校内")),
            createdAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚"),
            state: mapState(dto.state),
            previewImageURL: RemoteMapperSupport.sanitizedTextList(dto.pictureURL).first
        )
    }

    nonisolated static func mapState(_ value: Int?) -> LostFoundItemState {
        switch value {
        case 1:
            return .resolved
        case 2:
            return .systemDeleted
        default:
            return .active
        }
    }

    nonisolated private static func displayName(in values: [String], index: Int?, fallback: String) -> String {
        guard let index, values.indices.contains(index) else { return fallback }
        return values[index]
    }
}
