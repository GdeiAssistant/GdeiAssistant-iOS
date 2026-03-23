import Foundation

enum SecretRemoteMapper {
    nonisolated static let themeIDs = Array(1...12)

    nonisolated static func mapPosts(_ dtos: [SecretPostDTO]) -> [SecretPost] {
        dtos
            .filter { ($0.state ?? 0) != 2 }
            .map(mapPost)
            .sorted { $0.createdAt > $1.createdAt }
    }

    nonisolated static func mapPublishDTO(_ draft: SecretDraft) -> SecretPublishRemoteDTO {
        SecretPublishRemoteDTO(
            theme: draft.themeID,
            content: draft.content,
            type: draft.mode.rawValue,
            timer: draft.timerEnabled ? 1 : 0
        )
    }

    nonisolated static func mapPublishFields(_ dto: SecretPublishRemoteDTO) -> [FormFieldValue] {
        var fields = [
            FormFieldValue(name: "theme", value: String(dto.theme)),
            FormFieldValue(name: "type", value: String(dto.type)),
            FormFieldValue(name: "timer", value: String(dto.timer))
        ]
        if let content = dto.content, !content.isEmpty {
            fields.append(FormFieldValue(name: "content", value: content))
        }
        return fields
    }

    nonisolated static func mapDetail(_ dto: SecretPostDTO, comments: [SecretCommentDTO]?) -> SecretPostDetail {
        let resolvedComments = comments ?? dto.secretCommentList ?? []

        return SecretPostDetail(
            post: mapPost(dto),
            content: RemoteMapperSupport.firstNonEmpty(dto.content, "暂无内容"),
            comments: mapComments(resolvedComments)
        )
    }

    nonisolated static func normalizedTheme(_ theme: Int?) -> Int {
        let value = theme ?? 1
        return themeIDs.contains(value) ? value : 1
    }

    nonisolated private static func mapPost(_ dto: SecretPostDTO) -> SecretPost {
        let content = RemoteMapperSupport.firstNonEmpty(dto.content, dto.voiceURL, "暂无内容")
        let type = dto.type ?? 0
        let timer = dto.timer ?? 0
        let state = dto.state ?? 0
        let themeID = normalizedTheme(dto.theme)

        return SecretPost(
            id: String(dto.id ?? Int.random(in: 1...999_999)),
            username: RemoteMapperSupport.firstNonEmpty(dto.username, "匿名同学"),
            themeID: themeID,
            title: type == 0 ? RemoteMapperSupport.truncated(content, limit: 18) : "语音树洞",
            summary: type == 0 ? RemoteMapperSupport.truncated(content, limit: 48) : "点击进入详情播放语音内容",
            createdAt: createdAtText(dto.publishTime, timer: timer),
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0,
            isLiked: (dto.liked ?? 0) == 1,
            type: type,
            timer: timer,
            state: state,
            voiceURL: RemoteMapperSupport.sanitizedText(dto.voiceURL)
        )
    }

    nonisolated static func mapComments(_ dtos: [SecretCommentDTO]) -> [SecretComment] {
        dtos.map {
            SecretComment(
                id: String($0.id ?? Int.random(in: 1...999_999)),
                authorName: RemoteMapperSupport.firstNonEmpty($0.username, "匿名同学"),
                content: RemoteMapperSupport.firstNonEmpty($0.comment, ""),
                createdAt: RemoteMapperSupport.dateText($0.publishTime, fallback: "刚刚"),
                avatarTheme: $0.avatarTheme ?? 1
            )
        }
    }

    nonisolated private static func createdAtText(_ publishTime: RemoteFlexibleString?, timer: Int) -> String {
        let base = RemoteMapperSupport.dateText(publishTime, fallback: "刚刚")
        return timer == 1 ? "\(base) · 24 小时后自动删除" : base
    }
}
