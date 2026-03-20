import Foundation

enum DatingRemoteMapper {
    nonisolated static func mapProfile(_ dto: DatingProfileDTO, isMine: Bool = false) -> DatingProfile {
        let faculty = RemoteMapperSupport.firstNonEmpty(dto.faculty, "未填写学院")
        let hometown = RemoteMapperSupport.firstNonEmpty(dto.hometown, "未填写家乡")
        let grade = gradeText(dto.grade)
        let area = DatingArea(rawValue: dto.area ?? 0) ?? .girl
        return DatingProfile(
            id: dto.profileId.map(String.init) ?? UUID().uuidString,
            nickname: RemoteMapperSupport.firstNonEmpty(dto.nickname, "匿名"),
            headline: "\(grade) · \(faculty)",
            college: faculty,
            major: hometown,
            grade: grade,
            tags: [
                DatingTag(id: "area", title: area.title),
                DatingTag(id: "hometown", title: hometown)
            ],
            bio: RemoteMapperSupport.firstNonEmpty(dto.content, "这个人还没有留下更多介绍。"),
            imageURL: RemoteMapperSupport.sanitizedText(dto.pictureURL),
            hometown: hometown,
            qq: RemoteMapperSupport.sanitizedText(dto.qq),
            wechat: RemoteMapperSupport.sanitizedText(dto.wechat),
            isContactVisible: false,
            area: area
        )
    }

    nonisolated static func mapProfileDetail(_ dto: DatingProfileDetailDTO) -> DatingProfileDetail {
        let profileDTO = dto.profile ?? DatingProfileDTO(
            profileId: nil,
            username: nil,
            nickname: nil,
            grade: nil,
            faculty: nil,
            hometown: nil,
            content: nil,
            qq: nil,
            wechat: nil,
            area: nil,
            state: nil,
            pictureURL: nil
        )
        var profile = mapProfile(profileDTO)
        profile = DatingProfile(
            id: profile.id,
            nickname: profile.nickname,
            headline: profile.headline,
            college: profile.college,
            major: profile.major,
            grade: profile.grade,
            tags: profile.tags,
            bio: profile.bio,
            imageURL: RemoteMapperSupport.firstNonEmpty(dto.pictureURL, profile.imageURL),
            hometown: profile.hometown,
            qq: profile.qq,
            wechat: profile.wechat,
            isContactVisible: dto.isContactVisible == true,
            area: profile.area
        )
        return DatingProfileDetail(
            profile: profile,
            isPickNotAvailable: dto.isPickNotAvailable == true
        )
    }

    nonisolated static func multipartFiles(from image: UploadImageAsset?) -> [MultipartFormFile] {
        guard let image else { return [] }
        return [
            MultipartFormFile(
                name: "image",
                fileName: image.fileName,
                mimeType: image.mimeType,
                data: image.data
            )
        ]
    }

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
        let profile = mapProfile(dto, isMine: true)
        return DatingMyPost(
            id: profile.id,
            name: profile.nickname,
            imageURL: profile.imageURL,
            publishTime: "已发布",
            grade: profile.grade,
            faculty: profile.college,
            hometown: profile.hometown,
            area: profile.area,
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
