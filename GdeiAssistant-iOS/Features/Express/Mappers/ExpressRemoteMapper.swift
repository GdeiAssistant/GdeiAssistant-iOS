import Foundation

enum ExpressRemoteMapper {
    nonisolated static func mapPost(_ dto: ExpressRemoteDTO) -> ExpressPost {
        ExpressPost(
            id: RemoteMapperSupport.text(dto.id, fallback: UUID().uuidString),
            nickname: RemoteMapperSupport.firstNonEmpty(dto.nickname, dto.username, "匿名同学"),
            targetName: RemoteMapperSupport.firstNonEmpty(dto.name, "某位同学"),
            contentPreview: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(dto.content), limit: 72),
            publishTime: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚"),
            likeCount: RemoteMapperSupport.int(dto.likeCount),
            commentCount: RemoteMapperSupport.int(dto.commentCount),
            guessCount: RemoteMapperSupport.int(dto.guessSum),
            correctGuessCount: RemoteMapperSupport.int(dto.guessCount),
            isLiked: isTrue(dto.liked),
            canGuess: isTrue(dto.canGuess),
            selfGender: gender(dto.selfGender),
            targetGender: gender(dto.personGender)
        )
    }

    nonisolated static func mapDetail(_ dto: ExpressRemoteDTO) -> ExpressPostDetail {
        ExpressPostDetail(
            post: mapPost(dto),
            realName: dto.realname?.trimmingCharacters(in: .whitespacesAndNewlines),
            content: RemoteMapperSupport.firstNonEmpty(dto.content)
        )
    }

    nonisolated static func mapComment(_ dto: ExpressCommentRemoteDTO) -> ExpressCommentItem {
        ExpressCommentItem(
            id: RemoteMapperSupport.text(dto.id, fallback: UUID().uuidString),
            authorName: RemoteMapperSupport.firstNonEmpty(dto.nickname, dto.username, "同学"),
            content: RemoteMapperSupport.firstNonEmpty(dto.comment),
            publishTime: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚")
        )
    }

    nonisolated static func formFields(for draft: ExpressDraft) -> [FormFieldValue] {
        [
            FormFieldValue(name: "nickname", value: draft.nickname),
            FormFieldValue(name: "realname", value: draft.realName ?? ""),
            FormFieldValue(name: "selfGender", value: String(draft.selfGender.rawValue)),
            FormFieldValue(name: "name", value: draft.targetName),
            FormFieldValue(name: "content", value: draft.content),
            FormFieldValue(name: "personGender", value: String(draft.targetGender.rawValue))
        ]
    }

    nonisolated private static func gender(_ value: RemoteFlexibleString?) -> ExpressGender {
        ExpressGender(rawValue: RemoteMapperSupport.int(value, fallback: 2)) ?? .secret
    }

    nonisolated private static func isTrue(_ value: RemoteFlexibleString?) -> Bool {
        let raw = RemoteMapperSupport.text(value).lowercased()
        return raw == "true" || raw == "1"
    }
}
