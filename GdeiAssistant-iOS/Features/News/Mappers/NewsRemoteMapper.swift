import Foundation

enum NewsRemoteMapper {
    nonisolated static func mapItems(_ dtos: [AnnouncementRemoteDTO]) -> [NewsItem] {
        dtos.map { dto in
            NewsItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
                title: RemoteMapperSupport.firstNonEmpty(dto.title, "校园通知"),
                publishDate: RemoteMapperSupport.dateText(dto.publishTime, fallback: "今日"),
                content: RemoteMapperSupport.firstNonEmpty(dto.content, "暂无详细内容")
            )
        }
    }
}
