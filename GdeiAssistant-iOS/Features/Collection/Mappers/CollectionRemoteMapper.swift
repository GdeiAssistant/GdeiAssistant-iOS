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
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, localizedString("collection.fallback.untitled")),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, localizedString("collection.fallback.author")),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, localizedString("collection.fallback.publisher")),
            detailURL: detailURL
        )
    }

    nonisolated static func mapDetail(_ dto: CollectionDetailDTO) -> CollectionDetailInfo {
        CollectionDetailInfo(
            id: RemoteMapperSupport.firstNonEmpty(dto.bookname, UUID().uuidString),
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, localizedString("collection.fallback.detailTitle")),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, localizedString("collection.fallback.author")),
            principal: RemoteMapperSupport.firstNonEmpty(dto.principal, dto.personalPrincipal, localizedString("collection.fallback.principal")),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, localizedString("collection.fallback.publisher")),
            price: RemoteMapperSupport.firstNonEmpty(dto.price, localizedString("collection.fallback.price")),
            physicalDescription: RemoteMapperSupport.firstNonEmpty(dto.physicalDescriptionArea, localizedString("collection.fallback.description")),
            subjectTheme: RemoteMapperSupport.firstNonEmpty(dto.subjectTheme, localizedString("collection.fallback.subject")),
            classification: RemoteMapperSupport.firstNonEmpty(dto.chineseLibraryClassification, localizedString("collection.fallback.classification")),
            distributions: (dto.collectionDistributionList ?? []).map(mapDistribution)
        )
    }

    nonisolated static func mapDistribution(_ dto: CollectionDistributionDTO) -> CollectionDistributionItem {
        let barcode = RemoteMapperSupport.firstNonEmpty(dto.barcode, UUID().uuidString)
        return CollectionDistributionItem(
            id: barcode,
            location: RemoteMapperSupport.firstNonEmpty(dto.location, localizedString("collection.fallback.location")),
            callNumber: RemoteMapperSupport.firstNonEmpty(dto.callNumber, localizedString("collection.fallback.callNumber")),
            barcode: barcode,
            state: RemoteMapperSupport.firstNonEmpty(dto.state, localizedString("collection.fallback.state"))
        )
    }

    nonisolated static func mapBorrowItems(_ dtos: [CollectionBorrowDTO]) -> [CollectionBorrowItem] {
        dtos.map { dto in
            CollectionBorrowItem(
                id: RemoteMapperSupport.firstNonEmpty(dto.id, dto.sn, UUID().uuidString),
                sn: RemoteMapperSupport.firstNonEmpty(dto.sn, ""),
                code: RemoteMapperSupport.firstNonEmpty(dto.code, ""),
                title: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("collection.fallback.unknownBook")),
                author: RemoteMapperSupport.firstNonEmpty(dto.author, localizedString("collection.fallback.author")),
                borrowDate: RemoteMapperSupport.firstNonEmpty(dto.borrowDate, localizedString("collection.fallback.borrowDate")),
                returnDate: RemoteMapperSupport.firstNonEmpty(dto.returnDate, localizedString("collection.fallback.returnDate")),
                renewCount: dto.renewTime ?? 0
            )
        }
    }
}
