import Foundation

enum CardRemoteMapper {
    nonisolated static func queryRequest(for date: Date) -> CardQueryRequestDTO {
        let calendar = Calendar(identifier: .gregorian)
        return CardQueryRequestDTO(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            date: calendar.component(.day, from: date)
        )
    }

    nonisolated static func mapLossRequest(_ request: CardLossRequest) -> CardLossRemoteDTO {
        CardLossRemoteDTO(cardPassword: FormValidationSupport.trimmed(request.cardPassword))
    }

    nonisolated static func mapDashboard(
        infoDTO: CardInfoDTO,
        queryDTO: CardQueryResultDTO?
    ) -> CampusCardDashboard {
        let resolvedInfo = queryDTO?.cardInfo ?? infoDTO
        let transactions = (queryDTO?.cardList ?? []).map(mapTransaction)
        let lastUpdated = transactions.first?.timeText ?? localizedString("card.mapper.justUpdated")

        return CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: RemoteMapperSupport.firstNonEmpty(
                    RemoteMapperSupport.text(resolvedInfo.cardNumber),
                    RemoteMapperSupport.text(resolvedInfo.number),
                    localizedString("card.mapper.defaultCardNumber")
                ),
                ownerName: RemoteMapperSupport.firstNonEmpty(
                    RemoteMapperSupport.text(resolvedInfo.name),
                    localizedString("card.mapper.defaultOwner")
                ),
                balance: RemoteMapperSupport.double(resolvedInfo.cardBalance),
                status: mapStatus(info: resolvedInfo),
                lastUpdated: lastUpdated
            ),
            transactions: transactions
        )
    }

    nonisolated private static func mapStatus(info: CardInfoDTO) -> CardStatus {
        let lostState = RemoteMapperSupport.text(info.cardLostState).lowercased()
        let freezeState = RemoteMapperSupport.text(info.cardFreezeState).lowercased()

        if lostState.contains("挂失") || lostState.contains("lost") || lostState.contains("是") {
            return .lost
        }

        if freezeState.contains("冻结") || freezeState.contains("frozen") || freezeState.contains("是") {
            return .frozen
        }

        return .normal
    }

    nonisolated private static func mapTransaction(_ dto: CardTransactionDTO) -> CardTransaction {
        let timeText = RemoteMapperSupport.dateText(dto.tradeTime, fallback: localizedString("card.mapper.pendingTime"))
        let merchantName = RemoteMapperSupport.firstNonEmpty(
            RemoteMapperSupport.text(dto.merchantName),
            RemoteMapperSupport.text(dto.tradeName),
            localizedString("card.mapper.unknownMerchant")
        )
        let category = RemoteMapperSupport.firstNonEmpty(
            RemoteMapperSupport.text(dto.tradeName),
            localizedString("card.mapper.campusSpending")
        )
        let amount = abs(RemoteMapperSupport.double(dto.tradePrice))

        return CardTransaction(
            id: [timeText, merchantName, category].joined(separator: "-"),
            timeText: timeText,
            merchantName: merchantName,
            amount: amount,
            category: category
        )
    }
}
