import Foundation

enum DatingRemoteMapper {
    static let areaTags: [DatingTag] = [
        DatingTag(id: "area_0", title: "小姐姐"),
        DatingTag(id: "area_1", title: "小哥哥")
    ]

    nonisolated static func area(from filter: DatingFilter) -> Int {
        filter.area.rawValue
    }

    nonisolated static func mapProfiles(_ dtos: [DatingProfileDTO]) -> [DatingProfile] {
        dtos
            .filter { ($0.state ?? 1) != 0 }
            .map { mapProfile($0) }
    }

    nonisolated static func mapDetail(_ dto: DatingProfileDetailDTO) throws -> DatingProfileDetail {
        guard let profileDTO = dto.profile else {
            throw NetworkError.noData
        }
        let profile = mapProfile(profileDTO, pictureURL: dto.pictureURL, isContactVisible: dto.isContactVisible ?? false)
        return DatingProfileDetail(profile: profile, isPickNotAvailable: dto.isPickNotAvailable ?? false)
    }

    nonisolated static func mapReceivedPick(_ dto: DatingMessageDTO) -> DatingReceivedPick {
        let pick = dto.datingPick ?? dto.roommatePick
        let profile = pick?.datingProfile ?? pick?.roommateProfile
        return DatingReceivedPick(
            id: pick?.pickId.map(String.init) ?? UUID().uuidString,
            senderName: RemoteMapperSupport.firstNonEmpty(profile?.nickname, pick?.username, dto.username, "匿名"),
            content: RemoteMapperSupport.firstNonEmpty(pick?.content, "对方没有留下更多信息"),
            time: RemoteMapperSupport.firstNonEmpty(pick?.createTime, dto.createTime, "刚刚"),
            status: pickStatus(pick?.state),
            avatarURL: RemoteMapperSupport.sanitizedText(profile?.pictureURL)
        )
    }

    nonisolated static func mapSentPick(_ dto: DatingPickDTO) -> DatingSentPick {
        let profile = dto.datingProfile ?? dto.roommateProfile
        return DatingSentPick(
            id: dto.pickId.map(String.init) ?? UUID().uuidString,
            targetName: RemoteMapperSupport.firstNonEmpty(profile?.nickname, "匿名"),
            content: RemoteMapperSupport.firstNonEmpty(dto.content, "未填写留言"),
            status: pickStatus(dto.state),
            targetQq: profile?.qq,
            targetWechat: profile?.wechat,
            targetAvatarURL: RemoteMapperSupport.sanitizedText(profile?.pictureURL)
        )
    }

    nonisolated static func mapMyPost(_ dto: DatingProfileDTO) -> DatingMyPost {
        let area = DatingArea(rawValue: dto.area ?? 0) ?? .girl
        return DatingMyPost(
            id: dto.profileId.map(String.init) ?? UUID().uuidString,
            name: RemoteMapperSupport.firstNonEmpty(dto.nickname, "匿名"),
            imageURL: RemoteMapperSupport.sanitizedText(dto.pictureURL),
            publishTime: "",
            grade: gradeText(dto.grade),
            faculty: RemoteMapperSupport.firstNonEmpty(dto.faculty, "未填写专业"),
            hometown: RemoteMapperSupport.firstNonEmpty(dto.hometown, "未填写家乡"),
            area: area,
            state: dto.state ?? 1
        )
    }

    nonisolated static func publishFields(for draft: DatingPublishDraft) -> [FormFieldValue] {
        var fields = [
            FormFieldValue(name: "nickname", value: draft.nickname),
            FormFieldValue(name: "grade", value: String(draft.grade)),
            FormFieldValue(name: "area", value: String(draft.area.rawValue)),
            FormFieldValue(name: "faculty", value: draft.faculty),
            FormFieldValue(name: "hometown", value: draft.hometown),
            FormFieldValue(name: "content", value: draft.content)
        ]
        if let qq = draft.qq, !qq.isEmpty {
            fields.append(FormFieldValue(name: "qq", value: qq))
        }
        if let wechat = draft.wechat, !wechat.isEmpty {
            fields.append(FormFieldValue(name: "wechat", value: wechat))
        }
        return fields
    }

    nonisolated static func publishFiles(for draft: DatingPublishDraft) -> [MultipartFormFile] {
        guard let image = draft.image else { return [] }
        return [MultipartFormFile(name: "image", fileName: image.fileName, mimeType: image.mimeType, data: image.data)]
    }

    nonisolated private static func mapProfile(_ dto: DatingProfileDTO, pictureURL: String? = nil, isContactVisible: Bool = false) -> DatingProfile {
        let resolvedArea = DatingArea(rawValue: dto.area ?? 0) ?? .girl
        let qq = dto.qq?.trimmingCharacters(in: .whitespacesAndNewlines)
        let wechat = dto.wechat?.trimmingCharacters(in: .whitespacesAndNewlines)
        let bio = RemoteMapperSupport.firstNonEmpty(dto.content, "TA 暂时还没有留下更多介绍")

        return DatingProfile(
            id: dto.profileId.map(String.init) ?? UUID().uuidString,
            nickname: RemoteMapperSupport.firstNonEmpty(dto.nickname, dto.username, "校园同学"),
            headline: RemoteMapperSupport.truncated(bio, limit: 28),
            college: RemoteMapperSupport.firstNonEmpty(dto.faculty, "未公开专业"),
            major: RemoteMapperSupport.firstNonEmpty(dto.faculty, "未公开专业"),
            grade: gradeText(dto.grade),
            tags: [DatingTag(id: "area_\(resolvedArea.rawValue)", title: resolvedArea.title)],
            bio: bio,
            imageURL: RemoteMapperSupport.sanitizedText(RemoteMapperSupport.firstNonEmpty(pictureURL, dto.pictureURL)),
            hometown: RemoteMapperSupport.firstNonEmpty(dto.hometown, "未公开地区"),
            qq: isContactVisible ? qq : nil,
            wechat: isContactVisible ? wechat : nil,
            isContactVisible: isContactVisible,
            area: resolvedArea
        )
    }

    nonisolated private static func gradeText(_ value: Int?) -> String {
        switch value {
        case 1:
            return "大一"
        case 2:
            return "大二"
        case 3:
            return "大三"
        case 4:
            return "大四"
        default:
            return "未知年级"
        }
    }

    nonisolated private static func pickStatus(_ state: Int?) -> DatingPickStatus {
        switch state {
        case 1:
            return .accepted
        case -1, 2:
            return .rejected
        default:
            return .pending
        }
    }
}
