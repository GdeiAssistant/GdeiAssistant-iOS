import Foundation

enum LibraryRemoteMapper {
    nonisolated static func mapBooks(_ dto: BookSearchResponseDTO) -> [LibraryBook] {
        (dto.list ?? []).map { item in
            LibraryBook(
                id: RemoteMapperSupport.firstNonEmpty(item.detailURL, UUID().uuidString),
                title: RemoteMapperSupport.firstNonEmpty(item.bookname, "未命名图书"),
                author: RemoteMapperSupport.firstNonEmpty(item.author, "作者未知"),
                availableCount: 0,
                location: RemoteMapperSupport.firstNonEmpty(item.publishingHouse, "点击查看馆藏详情")
            )
        }
    }

    nonisolated static func mapRenewRequest(_ request: LibraryRenewRequest) -> LibraryRenewRequestDTO {
        LibraryRenewRequestDTO(
            sn: FormValidationSupport.trimmed(request.sn),
            code: FormValidationSupport.trimmed(request.code),
            password: FormValidationSupport.trimmed(request.password)
        )
    }

    nonisolated static func mapBookDetail(bookID: String, dto: LibraryCollectionDetailDTO) -> LibraryBookDetail {
        let distributions = dto.collectionDistributionList ?? []
        let availableCount = distributions.filter { distribution in
            let state = distribution.state?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return state.contains("可借") || state.contains("在馆")
        }.count

        let location = distributions.first?.location ?? "馆藏位置待更新"
        let summaryParts = [
            dto.subjectTheme,
            dto.personalPrincipal,
            dto.physicalDescriptionArea,
            dto.price
        ].compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }

        return LibraryBookDetail(
            id: bookID,
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, "未命名图书"),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, "作者未知"),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, "出版社未知"),
            isbn: RemoteMapperSupport.firstNonEmpty(dto.chineseLibraryClassification, dto.principal, "暂无馆藏编号"),
            summary: summaryParts.isEmpty ? "暂无馆藏说明" : summaryParts.joined(separator: "\n"),
            availableCount: availableCount,
            location: location
        )
    }

    nonisolated static func mapBorrowRecords(_ dtos: [BorrowBookDTO]) -> [BorrowRecord] {
        dtos.map { item in
            let renewTime = item.renewTime ?? 0
            let hasRenewToken = !(item.sn?.isEmpty ?? true) && !(item.code?.isEmpty ?? true)

            return BorrowRecord(
                id: RemoteMapperSupport.firstNonEmpty(item.id, item.sn, UUID().uuidString),
                bookTitle: RemoteMapperSupport.firstNonEmpty(item.name, "未命名图书"),
                borrowDate: RemoteMapperSupport.dateText(item.borrowDate, fallback: "待定"),
                dueDate: RemoteMapperSupport.dateText(item.returnDate, fallback: "待定"),
                status: renewTime > 0 ? "已续借\(renewTime)次" : "待归还",
                renewable: hasRenewToken,
                sn: item.sn,
                code: item.code
            )
        }
    }
}
