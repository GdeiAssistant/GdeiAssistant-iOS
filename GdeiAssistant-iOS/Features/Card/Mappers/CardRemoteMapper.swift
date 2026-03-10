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

    nonisolated static func mapLossQueryItems(_ dto: CardLossRemoteDTO) -> [URLQueryItem] {
        [URLQueryItem(name: "cardPassword", value: dto.cardPassword)]
    }

    nonisolated static func mapDashboard(
        infoDTO: CardInfoDTO,
        queryDTO: CardQueryResultDTO?
    ) -> CampusCardDashboard {
        let resolvedInfo = queryDTO?.cardInfo ?? infoDTO
        let transactions = (queryDTO?.cardList ?? []).map(mapTransaction)
        let lastUpdated = transactions.first?.timeText ?? "刚刚更新"

        return CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: RemoteMapperSupport.firstNonEmpty(
                    RemoteMapperSupport.text(resolvedInfo.cardNumber),
                    RemoteMapperSupport.text(resolvedInfo.number),
                    "未获取卡号"
                ),
                ownerName: RemoteMapperSupport.firstNonEmpty(
                    RemoteMapperSupport.text(resolvedInfo.name),
                    "校园卡用户"
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
        let timeText = RemoteMapperSupport.dateText(dto.tradeTime, fallback: "待定时间")
        let merchantName = RemoteMapperSupport.firstNonEmpty(
            RemoteMapperSupport.text(dto.merchantName),
            RemoteMapperSupport.text(dto.tradeName),
            "未知商户"
        )
        let category = RemoteMapperSupport.firstNonEmpty(
            RemoteMapperSupport.text(dto.tradeName),
            "校园消费"
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
