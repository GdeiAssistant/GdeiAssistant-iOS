import Foundation

enum LibraryRemoteMapper {
    nonisolated static func mapBooks(_ dto: BookSearchResponseDTO) -> [LibraryBook] {
        (dto.collectionList ?? []).map { item in
            LibraryBook(
                id: RemoteMapperSupport.firstNonEmpty(item.detailURL, UUID().uuidString),
                title: RemoteMapperSupport.firstNonEmpty(item.bookname, localizedString("library.mapper.unnamedBook")),
                author: RemoteMapperSupport.firstNonEmpty(item.author, localizedString("library.mapper.unknownAuthor")),
                availableCount: 0,
                location: RemoteMapperSupport.firstNonEmpty(item.publishingHouse, localizedString("library.mapper.viewHoldings"))
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
            return state.contains("可借") || state.contains("在馆") || state.contains("Available") || state.contains("In Library")
        }.count

        let location = distributions.first?.location ?? localizedString("library.mapper.locationPending")
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
            title: RemoteMapperSupport.firstNonEmpty(dto.bookname, localizedString("library.mapper.unnamedBook")),
            author: RemoteMapperSupport.firstNonEmpty(dto.author, localizedString("library.mapper.unknownAuthor")),
            publisher: RemoteMapperSupport.firstNonEmpty(dto.publishingHouse, localizedString("library.mapper.unknownPublisher")),
            isbn: RemoteMapperSupport.firstNonEmpty(dto.chineseLibraryClassification, dto.principal, localizedString("library.mapper.noISBN")),
            summary: summaryParts.isEmpty ? localizedString("library.mapper.noSummary") : summaryParts.joined(separator: "\n"),
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
                bookTitle: RemoteMapperSupport.firstNonEmpty(item.name, localizedString("library.mapper.unnamedBook")),
                borrowDate: RemoteMapperSupport.dateText(item.borrowDate, fallback: localizedString("library.mapper.pending")),
                dueDate: RemoteMapperSupport.dateText(item.returnDate, fallback: localizedString("library.mapper.pending")),
                status: renewTime > 0 ? localizedString("library.mapper.renewed") + "\(renewTime)" + localizedString("library.mapper.times") : localizedString("library.mapper.toReturn"),
                renewable: hasRenewToken,
                sn: item.sn,
                code: item.code
            )
        }
    }
}
