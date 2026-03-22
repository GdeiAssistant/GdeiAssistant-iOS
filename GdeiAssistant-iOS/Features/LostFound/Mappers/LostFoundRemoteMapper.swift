import Foundation

enum LostFoundRemoteMapper {
    nonisolated static var itemTypes: [String] {
        [
            localizedString("lostFound.itemType.phone"),
            localizedString("lostFound.itemType.campusCard"),
            localizedString("lostFound.itemType.idCard"),
            localizedString("lostFound.itemType.bankCard"),
            localizedString("lostFound.itemType.book"),
            localizedString("lostFound.itemType.key"),
            localizedString("lostFound.itemType.bag"),
            localizedString("lostFound.itemType.clothing"),
            localizedString("lostFound.itemType.campusTransport"),
            localizedString("lostFound.itemType.sportsFitness"),
            localizedString("lostFound.itemType.digitalAccessory"),
            localizedString("lostFound.itemType.other")
        ]
    }
    nonisolated static var stateTypes: [String] {
        [
            localizedString("lostFound.state.active"),
            localizedString("lostFound.state.confirmed"),
            localizedString("lostFound.state.systemDeleted")
        ]
    }

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
        displayName(in: itemTypes, index: itemTypeID, fallback: localizedString("lostFound.itemType.other"))
    }

    nonisolated static func mapDetail(_ dto: LostFoundDetailDTO) throws -> LostFoundDetail {
        guard let itemDTO = dto.item else {
            throw NetworkError.noData
        }

        let item = mapItem(itemDTO, fallbackType: (itemDTO.lostType ?? 0) == 0 ? .lost : .found)
        let statusText = displayName(in: stateTypes, index: itemDTO.state, fallback: localizedString("lostFound.mapper.statusUnknown"))
        let contactHint = [
            itemDTO.qq.flatMap { $0.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactQQ"))\($0)" },
            itemDTO.wechat.flatMap { $0.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactWechat"))\($0)" },
            itemDTO.phone.flatMap { $0.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactPhone"))\($0)" }
        ].compactMap { $0 }.joined(separator: " / ")

        return LostFoundDetail(
            item: item,
            description: RemoteMapperSupport.firstNonEmpty(itemDTO.description, localizedString("lostFound.mapper.noDescription")),
            contactHint: contactHint.isEmpty ? localizedString("lostFound.mapper.noContact") : contactHint,
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
            nickname: RemoteMapperSupport.firstNonEmpty(profile.nickname, profile.username, localizedString("lostFound.mapper.defaultUser")),
            introduction: RemoteMapperSupport.firstNonEmpty(profile.introduction, localizedString("lostFound.mapper.defaultIntro")),
            lost: (dto.lost ?? []).map { mapItem($0, fallbackType: .lost) },
            found: (dto.found ?? []).map { mapItem($0, fallbackType: .found) },
            didFound: (dto.didfound ?? []).map { mapItem($0, fallbackType: ($0.lostType ?? 0) == 0 ? .lost : .found) }
        )
    }

    nonisolated private static func mapItem(_ dto: LostFoundItemDTO, fallbackType: LostFoundType) -> LostFoundItem {
        LostFoundItem(
            id: String(dto.id ?? Int.random(in: 1...999_999)),
            title: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("lostFound.mapper.unnamedItem")),
            type: fallbackType,
            itemTypeID: dto.itemType ?? 0,
            summary: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(dto.description, localizedString("lostFound.mapper.noSummary")), limit: 56),
            location: RemoteMapperSupport.firstNonEmpty(dto.location, displayName(in: itemTypes, index: dto.itemType, fallback: localizedString("lostFound.mapper.onCampus"))),
            createdAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: localizedString("lostFound.mapper.justNow")),
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
