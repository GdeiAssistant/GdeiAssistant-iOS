import Foundation

enum NewsRemoteMapper {
    nonisolated static func mapItems(_ dtos: [NewsRemoteDTO], category: NewsCategory) -> [NewsItem] {
        dtos.map { dto in
            NewsItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
                category: NewsCategory(rawValue: dto.type ?? category.rawValue) ?? category,
                title: RemoteMapperSupport.firstNonEmpty(dto.title, "校园通知"),
                publishDate: RemoteMapperSupport.firstNonEmpty(dto.publishDate, "今日"),
                content: RemoteMapperSupport.firstNonEmpty(dto.content, "暂无详细内容")
            )
        }
    }
}
