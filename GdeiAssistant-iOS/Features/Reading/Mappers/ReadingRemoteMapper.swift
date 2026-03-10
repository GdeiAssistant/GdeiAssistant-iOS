import Foundation

enum ReadingRemoteMapper {
    nonisolated static func mapItems(_ dtos: [ReadingRemoteDTO]) -> [ReadingItem] {
        dtos.map { dto in
            ReadingItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, UUID().uuidString),
                title: RemoteMapperSupport.firstNonEmpty(dto.title, "专题阅读"),
                summary: RemoteMapperSupport.firstNonEmpty(dto.description, "暂无摘要"),
                link: RemoteMapperSupport.firstNonEmpty(dto.link, ""),
                createdAt: RemoteMapperSupport.firstNonEmpty(dto.createTime, "最新")
            )
        }
    }
}
