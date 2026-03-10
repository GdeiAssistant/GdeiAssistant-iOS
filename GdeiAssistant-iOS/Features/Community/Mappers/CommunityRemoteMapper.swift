import Foundation

enum CommunityRemoteMapper {
    nonisolated static func mapPosts(_ dtos: [ExpressPostDTO], sort: CommunityFeedSort) -> [CommunityPost] {
        let posts = dtos.map(mapPost)
        return sortPosts(posts, sort: sort)
    }

    nonisolated static func mapPostDetail(_ dto: ExpressPostDTO) -> CommunityPostDetail {
        let post = mapPost(dto)
        return CommunityPostDetail(
            post: post,
            content: RemoteMapperSupport.firstNonEmpty(dto.content, post.summary),
            topics: post.tags.map { CommunityTopic(id: $0, title: $0, summary: "按关键词查看校园讨论") },
            isLiked: dto.liked ?? false
        )
    }

    nonisolated static func mapComments(_ dtos: [ExpressCommentDTO]) -> [CommunityComment] {
        dtos.map { item in
            CommunityComment(
                id: String(item.id ?? Int.random(in: 1...999_999)),
                authorName: RemoteMapperSupport.firstNonEmpty(item.nickname, item.username, "校园同学"),
                isAnonymous: false,
                createdAt: RemoteMapperSupport.dateText(item.publishTime, fallback: "刚刚"),
                content: RemoteMapperSupport.firstNonEmpty(item.comment, ""),
                likeCount: 0
            )
        }
    }

    nonisolated static func mapTopic(keyword: String) -> CommunityTopic {
        CommunityTopic(
            id: keyword,
            title: keyword,
            summary: "按关键词汇聚校园话题与相关讨论"
        )
    }

    nonisolated static func mapTopicPosts(_ dtos: [TopicPostDTO], keyword: String, sort: CommunityFeedSort) -> [CommunityPost] {
        let posts = dtos.map { item in
            CommunityPost(
                id: String(item.id ?? Int.random(in: 1...999_999)),
                authorName: RemoteMapperSupport.firstNonEmpty(item.username, "校园同学"),
                authorAvatarURL: item.firstImageUrl ?? "",
                isAnonymous: false,
                createdAt: RemoteMapperSupport.dateText(item.publishTime, fallback: "刚刚"),
                title: RemoteMapperSupport.firstNonEmpty(item.topic, RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(item.content, "校园话题"), limit: 18)),
                summary: RemoteMapperSupport.truncated(RemoteMapperSupport.firstNonEmpty(item.content, "暂无内容"), limit: 64),
                tags: [keyword],
                likeCount: item.likeCount ?? 0,
                commentCount: 0
            )
        }
        return sortPosts(posts, sort: sort)
    }

    nonisolated private static func mapPost(_ dto: ExpressPostDTO) -> CommunityPost {
        let targetName = RemoteMapperSupport.firstNonEmpty(dto.name)
        let content = RemoteMapperSupport.firstNonEmpty(dto.content, "暂无内容")
        let genderTag = expressGenderLabel(dto.personGender)
        var tags = [String]()
        if !targetName.isEmpty { tags.append(targetName) }
        if !genderTag.isEmpty { tags.append(genderTag) }
        if tags.isEmpty { tags.append("校园热议") }

        return CommunityPost(
            id: String(dto.id ?? Int.random(in: 1...999_999)),
            authorName: RemoteMapperSupport.firstNonEmpty(dto.nickname, dto.username, dto.realname, "校园同学"),
            authorAvatarURL: "",
            isAnonymous: false,
            createdAt: RemoteMapperSupport.dateText(dto.publishTime, fallback: "刚刚"),
            title: RemoteMapperSupport.firstNonEmpty(dto.name, RemoteMapperSupport.truncated(content, limit: 18), "校园动态"),
            summary: RemoteMapperSupport.truncated(content, limit: 72),
            tags: tags,
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0
        )
    }

    nonisolated private static func sortPosts(_ posts: [CommunityPost], sort: CommunityFeedSort) -> [CommunityPost] {
        switch sort {
        case .hot:
            return posts.sorted { lhs, rhs in
                if lhs.likeCount == rhs.likeCount {
                    if lhs.commentCount == rhs.commentCount {
                        return lhs.createdAt > rhs.createdAt
                    }
                    return lhs.commentCount > rhs.commentCount
                }
                return lhs.likeCount > rhs.likeCount
            }
        case .latest:
            return posts.sorted { $0.createdAt > $1.createdAt }
        }
    }

    nonisolated private static func expressGenderLabel(_ value: Int?) -> String {
        switch value {
        case 0:
            return "男生"
        case 1:
            return "女生"
        case 2:
            return "保密"
        default:
            return ""
        }
    }
}
