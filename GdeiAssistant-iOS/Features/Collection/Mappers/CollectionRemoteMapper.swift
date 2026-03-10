import Foundation

enum CollectionRemoteMapper {
    nonisolated static func mapSearchPage(_ dto: CollectionSearchResponseDTO) -> CollectionSearchPage {
        CollectionSearchPage(
            items: (dto.collectionList ?? []).map(mapSearchItem),
            sumPage: dto.sumPage ?? 0
        )
    }

    nonisolated static func mapSearchItem(_ dto: CollectionItemDTO) -> CollectionSearchItem {
        let detailURL = RemoteMapperSupport.firstNonEmpty(dto.detailURL, UUID().uuidString)
        return CollectionSearchItem(
            id: detailURL,
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, "未命名馆藏"),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, "作者暂缺"),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, "出版社暂缺"),
            detailURL: detailURL
        )
    }

    nonisolated static func mapDetail(_ dto: CollectionDetailDTO) -> CollectionDetailInfo {
        CollectionDetailInfo(
            id: RemoteMapperSupport.firstNonEmpty(dto.bookname, UUID().uuidString),
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, "馆藏详情"),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, "作者暂缺"),
            principal: RemoteMapperSupport.firstNonEmpty(dto.principal, dto.personalPrincipal, "无责任者信息"),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, "出版社暂缺"),
            price: RemoteMapperSupport.firstNonEmpty(dto.price, "价格暂缺"),
            physicalDescription: RemoteMapperSupport.firstNonEmpty(dto.physicalDescriptionArea, "暂无馆藏描述"),
            subjectTheme: RemoteMapperSupport.firstNonEmpty(dto.subjectTheme, "暂无主题词"),
            classification: RemoteMapperSupport.firstNonEmpty(dto.chineseLibraryClassification, "暂无分类号"),
            distributions: (dto.collectionDistributionList ?? []).map(mapDistribution)
        )
    }

    nonisolated static func mapDistribution(_ dto: CollectionDistributionDTO) -> CollectionDistributionItem {
        let barcode = RemoteMapperSupport.firstNonEmpty(dto.barcode, UUID().uuidString)
        return CollectionDistributionItem(
            id: barcode,
            location: RemoteMapperSupport.firstNonEmpty(dto.location, "馆藏位置待补充"),
            callNumber: RemoteMapperSupport.firstNonEmpty(dto.callNumber, "索书号暂缺"),
            barcode: barcode,
            state: RemoteMapperSupport.firstNonEmpty(dto.state, "状态未知")
        )
    }

    nonisolated static func mapBorrowItems(_ dtos: [CollectionBorrowDTO]) -> [CollectionBorrowItem] {
        dtos.map { dto in
            CollectionBorrowItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, dto.sn, UUID().uuidString),
                sn: RemoteMapperSupport.firstNonEmpty(dto.sn, ""),
                code: RemoteMapperSupport.firstNonEmpty(dto.code, ""),
                title: RemoteMapperSupport.firstNonEmpty(dto.name, "未知图书"),
                author: RemoteMapperSupport.firstNonEmpty(dto.author, "作者暂缺"),
                borrowDate: RemoteMapperSupport.firstNonEmpty(dto.borrowDate, "借阅时间未知"),
                returnDate: RemoteMapperSupport.firstNonEmpty(dto.returnDate, "归还时间未知"),
                renewCount: dto.renewTime ?? 0
            )
        }
    }
}
