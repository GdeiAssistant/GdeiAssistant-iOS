import Foundation

enum PhotographRemoteMapper {
    nonisolated static func mapPost(_ dto: PhotographRemoteDTO) -> PhotographPost {
        let category = PhotographCategory(rawValue: RemoteMapperSupport.int(dto.type, fallback: 0)) ?? .campus
        let firstImageURL = RemoteMapperSupport.sanitizedText(dto.firstImageUrl)
        let imageURLs = RemoteMapperSupport.sanitizedTextList(dto.imageUrls)
        return PhotographPost(
            id: RemoteMapperSupport.text(dto.id, fallback: UUID().uuidString),
            title: RemoteMapperSupport.firstNonEmpty(dto.title, localizedString("photograph.mapper.defaultTitle")),
            contentPreview: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(dto.content), limit: 60),
            authorName: RemoteMapperSupport.firstNonEmpty(dto.username, localizedString("photograph.mapper.defaultAuthor")),
            createdAt: RemoteMapperSupport.dateText(dto.createTime, fallback: localizedString("common.justNow")),
            likeCount: RemoteMapperSupport.int(dto.likeCount),
            commentCount: RemoteMapperSupport.int(dto.commentCount),
            photoCount: max(RemoteMapperSupport.int(dto.count), imageURLs.count, firstImageURL == nil ? 0 : 1),
            firstImageURL: firstImageURL,
            isLiked: isTrue(dto.liked),
            category: category
        )
    }

    nonisolated static func mapDetail(_ dto: PhotographRemoteDTO) -> PhotographPostDetail {
        let post = mapPost(dto)
        let imageURLs = RemoteMapperSupport.sanitizedTextList(dto.imageUrls)
        return PhotographPostDetail(
            post: post,
            content: RemoteMapperSupport.firstNonEmpty(dto.content, post.contentPreview),
            imageURLs: imageURLs.isEmpty ? [post.firstImageURL].compactMap { $0 } : imageURLs,
            comments: (dto.photographCommentList ?? []).map(mapComment)
        )
    }

    nonisolated static func mapComment(_ dto: PhotographCommentRemoteDTO) -> PhotographCommentItem {
        PhotographCommentItem(
            id: RemoteMapperSupport.text(dto.commentId, fallback: UUID().uuidString),
            photoID: RemoteMapperSupport.sanitizedText(RemoteMapperSupport.text(dto.photoId)),
            authorName: RemoteMapperSupport.firstNonEmpty(
                dto.nickname,
                dto.username,
                localizedString("photograph.mapper.defaultCommentAuthor")
            ),
            content: RemoteMapperSupport.firstNonEmpty(dto.comment),
            createdAt: RemoteMapperSupport.dateText(dto.createTime, fallback: localizedString("common.justNow"))
        )
    }

    nonisolated static func files(from draft: PhotographDraft) -> [MultipartFormFile] {
        draft.images.enumerated().map { index, image in
            MultipartFormFile(name: "image\(index + 1)", fileName: image.fileName, mimeType: image.mimeType, data: image.data)
        }
    }

    nonisolated private static func isTrue(_ value: RemoteFlexibleString?) -> Bool {
        let raw = RemoteMapperSupport.text(value).lowercased()
        return raw == "true" || raw == "1"
    }
}
