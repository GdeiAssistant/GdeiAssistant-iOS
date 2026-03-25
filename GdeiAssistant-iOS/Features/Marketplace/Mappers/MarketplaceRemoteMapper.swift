import Foundation

enum MarketplaceRemoteMapper {
    nonisolated static var itemTypes: [String] {
        LocalizedProfileCatalog.current.defaultOptions.marketplaceItemTypes.map(\.label)
    }

    nonisolated static func mapItems(_ dtos: [MarketplaceItemDTO]) -> [MarketplaceItem] {
        dtos
            .filter { mapState($0.state) == .selling }
            .map { mapItem($0, sellerName: $0.username) }
            .sorted { $0.postedAt > $1.postedAt }
    }

    nonisolated static func mapPublishDTO(_ draft: MarketplaceDraft) -> MarketplacePublishRemoteDTO {
        MarketplacePublishRemoteDTO(
            name: draft.title,
            description: draft.description,
            price: draft.price,
            location: draft.location,
            type: draft.typeID,
            qq: draft.qq,
            phone: draft.phone
        )
    }

    nonisolated static func mapUpdateDTO(_ draft: MarketplaceUpdateDraft) -> MarketplaceUpdateRemoteDTO {
        MarketplaceUpdateRemoteDTO(
            name: draft.title,
            description: draft.description,
            price: draft.price,
            location: draft.location,
            type: draft.typeID,
            qq: draft.qq,
            phone: draft.phone
        )
    }

    nonisolated static func mapPublishFields(_ dto: MarketplacePublishRemoteDTO) -> [FormFieldValue] {
        var fields = [
            FormFieldValue(name: "name", value: dto.name),
            FormFieldValue(name: "description", value: dto.description),
            FormFieldValue(name: "price", value: String(dto.price)),
            FormFieldValue(name: "location", value: dto.location),
            FormFieldValue(name: "type", value: String(dto.type))
        ]

        if let qq = dto.qq, !qq.isEmpty {
            fields.append(FormFieldValue(name: "qq", value: qq))
        }
        if let phone = dto.phone, !phone.isEmpty {
            fields.append(FormFieldValue(name: "phone", value: phone))
        }

        return fields
    }

    nonisolated static func mapPublishFiles(_ draft: MarketplaceDraft) -> [MultipartFormFile] {
        draft.images.enumerated().map { index, image in
            MultipartFormFile(
                name: "image\(index + 1)",
                fileName: image.fileName,
                mimeType: image.mimeType,
                data: image.data
            )
        }
    }

    nonisolated static func displayName(forType typeID: Int) -> String {
        displayName(in: itemTypes, index: typeID, fallback: localizedString("marketplace.mapper.other"))
    }

    nonisolated static func mapDetail(_ dto: MarketplaceDetailDTO) throws -> MarketplaceDetail {
        guard let itemDTO = dto.secondhandItem else {
            throw NetworkError.noData
        }

        let sellerName = RemoteMapperSupport.firstNonEmpty(
            dto.profile?.nickname,
            dto.profile?.username,
            itemDTO.username,
            localizedString("marketplace.mapper.defaultSeller")
        )
        let item = mapItem(itemDTO, sellerName: sellerName, sellerAvatarURL: dto.profile?.avatarURL)
        let typeName = displayName(in: itemTypes, index: itemDTO.type, fallback: localizedString("marketplace.mapper.defaultType"))
        let contactHint = [
            itemDTO.qq.flatMap { $0.isEmpty ? nil : localizedString("marketplace.contactQQPrefix") + $0 },
            itemDTO.phone.flatMap { $0.isEmpty ? nil : localizedString("marketplace.contactPhonePrefix") + $0 }
        ].compactMap { $0 }.joined(separator: " / ")
        let imageURLs = RemoteMapperSupport.sanitizedTextList(itemDTO.pictureURL)

        return MarketplaceDetail(
            item: item,
            condition: typeName,
            description: RemoteMapperSupport.firstNonEmpty(itemDTO.description, localizedString("marketplace.mapper.noDescription")),
            contactHint: contactHint.isEmpty ? localizedString("marketplace.contactUnavailable") : contactHint,
            sellerUsername: dto.profile?.username ?? itemDTO.username,
            sellerNickname: RemoteMapperSupport.sanitizedText(dto.profile?.nickname),
            sellerCollege: facultyName(dto.profile?.faculty),
            sellerMajor: RemoteMapperSupport.sanitizedText(dto.profile?.major),
            sellerGrade: enrollmentText(dto.profile?.enrollment),
            imageURLs: imageURLs
        )
    }

    nonisolated static func mapPersonalSummary(_ dto: MarketplacePersonalSummaryDTO, profile: UserProfileDTO) -> MarketplacePersonalSummary {
        MarketplacePersonalSummary(
            avatarURL: RemoteMapperSupport.sanitizedText(profile.avatar),
            nickname: RemoteMapperSupport.firstNonEmpty(profile.nickname, profile.username, localizedString("marketplace.mapper.defaultUser")),
            introduction: RemoteMapperSupport.firstNonEmpty(profile.introduction, localizedString("marketplace.mapper.defaultIntro")),
            doing: (dto.doing ?? []).map { mapItem($0, sellerName: profile.nickname ?? profile.username, sellerAvatarURL: profile.avatar) },
            sold: (dto.sold ?? []).map { mapItem($0, sellerName: profile.nickname ?? profile.username, sellerAvatarURL: profile.avatar) },
            off: (dto.off ?? []).map { mapItem($0, sellerName: profile.nickname ?? profile.username, sellerAvatarURL: profile.avatar) }
        )
    }

    nonisolated private static func mapItem(_ dto: MarketplaceItemDTO, sellerName: String?, sellerAvatarURL: String? = nil) -> MarketplaceItem {
        let typeName = displayName(in: itemTypes, index: dto.type, fallback: localizedString("marketplace.mapper.other"))
        let state = mapState(dto.state)
        let imageURLs = RemoteMapperSupport.sanitizedTextList(dto.pictureURL)

        return MarketplaceItem(
            id: String(dto.id ?? Int.random(in: 1...999_999)),
            title: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("marketplace.mapper.unnamedItem")),
            price: RemoteMapperSupport.double(dto.price),
            summary: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(dto.description, localizedString("marketplace.mapper.noSummary")), limit: 60),
            sellerName: RemoteMapperSupport.firstNonEmpty(sellerName, dto.username, localizedString("marketplace.mapper.defaultSeller")),
            sellerAvatarURL: RemoteMapperSupport.sanitizedText(sellerAvatarURL),
            postedAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: localizedString("common.justNow")),
            location: RemoteMapperSupport.firstNonEmpty(dto.location, localizedString("marketplace.mapper.onCampusPickup")),
            state: state,
            tags: [typeName],
            previewImageURL: imageURLs.first
        )
    }

    nonisolated static func mapState(_ value: Int?) -> MarketplaceItemState {
        switch value {
        case 0:
            return .offShelf
        case 2:
            return .sold
        case 3:
            return .systemDeleted
        default:
            return .selling
        }
    }

    nonisolated private static func displayName(in values: [String], index: Int?, fallback: String) -> String {
        guard let index, values.indices.contains(index) else { return fallback }
        return values[index]
    }

    nonisolated private static func facultyName(_ code: Int?) -> String? {
        guard let code else { return nil }
        let faculty = LocalizedProfileCatalog.current.defaultOptions.faculties.first(where: { $0.code == code })
        guard let faculty, faculty.code != 0 else { return nil }
        return faculty.label
    }

    nonisolated private static func enrollmentText(_ enrollment: Int?) -> String? {
        guard let enrollment else { return nil }
        return "\(enrollment)级"
    }
}
