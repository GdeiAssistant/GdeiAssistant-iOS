import Foundation

enum DatingRemoteMapper {
    nonisolated static func mapReceivedPick(_ dto: DatingPickDTO) -> DatingReceivedPick {
        let profile = dto.roommateProfile
        return DatingReceivedPick(
            id: dto.pickId.map(String.init) ?? UUID().uuidString,
            senderName: RemoteMapperSupport.firstNonEmpty(profile?.nickname, dto.username, "匿名"),
            content: RemoteMapperSupport.firstNonEmpty(dto.content, "对方没有留下更多信息"),
            time: "最近更新",
            status: pickStatus(dto.state),
            avatarURL: RemoteMapperSupport.sanitizedText(profile?.pictureURL)
        )
    }

    nonisolated static func mapSentPick(_ dto: DatingPickDTO) -> DatingSentPick {
        let profile = dto.roommateProfile
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
            publishTime: "已发布",
            grade: gradeText(dto.grade),
            faculty: RemoteMapperSupport.firstNonEmpty(dto.faculty, "未填写专业"),
            hometown: RemoteMapperSupport.firstNonEmpty(dto.hometown, "未填写家乡"),
            area: area,
            state: dto.state ?? 1
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
