import Foundation

enum TopicRemoteMapper {
    nonisolated static func mapPost(_ dto: TopicRemoteDTO) -> TopicPost {
        let topic = RemoteMapperSupport.firstNonEmpty(dto.topic, "校园话题")
        let content = RemoteMapperSupport.firstNonEmpty(dto.content)
        let firstImageURL = RemoteMapperSupport.sanitizedText(dto.firstImageUrl)
        let imageURLs = RemoteMapperSupport.sanitizedTextList(dto.imageUrls)
        return TopicPost(
            id: RemoteMapperSupport.text(dto.id, fallback: UUID().uuidString),
            topic: topic,
            contentPreview: RemoteMapperSupport.truncated(content, limit: 64),
            authorName: RemoteMapperSupport.firstNonEmpty(dto.username, "匿名同学"),
            publishedAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚"),
            likeCount: RemoteMapperSupport.int(dto.likeCount),
            imageCount: max(RemoteMapperSupport.int(dto.count), imageURLs.count, firstImageURL == nil ? 0 : 1),
            firstImageURL: firstImageURL,
            isLiked: isTrue(dto.liked)
        )
    }

    nonisolated static func mapDetail(_ dto: TopicRemoteDTO) -> TopicPostDetail {
        let post = mapPost(dto)
        let imageURLs = RemoteMapperSupport.sanitizedTextList(dto.imageUrls)
        let fallbackImages = imageURLs.isEmpty ? [post.firstImageURL].compactMap { $0 } : imageURLs
        return TopicPostDetail(
            post: post,
            content: RemoteMapperSupport.firstNonEmpty(dto.content, post.contentPreview),
            imageURLs: fallbackImages
        )
    }

    nonisolated static func multipartFiles(from images: [UploadImageAsset]) -> [MultipartFormFile] {
        images.map {
            MultipartFormFile(name: "images", fileName: $0.fileName, mimeType: $0.mimeType, data: $0.data)
        }
    }

    nonisolated private static func isTrue(_ value: RemoteFlexibleString?) -> Bool {
        let raw = RemoteMapperSupport.text(value).lowercased()
        return raw == "true" || raw == "1"
    }
}
