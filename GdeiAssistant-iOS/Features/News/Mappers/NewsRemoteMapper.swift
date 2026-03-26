import Foundation

enum NewsRemoteMapper {
    nonisolated static func mapItems(_ dtos: [NewsRemoteDTO]) -> [NewsItem] {
        dtos.map { dto in
            NewsItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
                type: dto.type ?? 1,
                title: RemoteMapperSupport.firstNonEmpty(dto.title, localizedString("news.mapper.defaultTitle")),
                publishDate: RemoteMapperSupport.firstNonEmpty(dto.publishDate, localizedString("news.mapper.today")),
                content: RemoteMapperSupport.firstNonEmpty(dto.content, localizedString("news.mapper.defaultContent")),
                sourceURL: dto.sourceUrl
            )
        }
    }
}
