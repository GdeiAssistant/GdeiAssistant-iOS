import Foundation

enum NewsRemoteMapper {
    nonisolated static func mapItems(_ dtos: [NewsRemoteDTO]) -> [NewsItem] {
        dtos.map { dto in
            NewsItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
                title: RemoteMapperSupport.firstNonEmpty(dto.title, "新闻通知"),
                publishDate: RemoteMapperSupport.firstNonEmpty(dto.publishDate, "今日"),
                content: RemoteMapperSupport.firstNonEmpty(dto.content, "暂无详细内容")
            )
        }
    }
}
