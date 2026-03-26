import Foundation

enum DeliveryRemoteMapper {
    nonisolated static func mapOrder(_ dto: DeliveryOrderRemoteDTO) -> DeliveryOrder {
        DeliveryOrder(
            orderID: RemoteMapperSupport.text(dto.orderId, fallback: UUID().uuidString),
            username: RemoteMapperSupport.firstNonEmpty(dto.username, localizedString("delivery.fallback.campusUser")),
            name: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("delivery.fallback.taskName")),
            pickupCode: RemoteMapperSupport.firstNonEmpty(dto.number),
            contactPhone: RemoteMapperSupport.firstNonEmpty(dto.phone),
            price: RemoteMapperSupport.double(dto.price),
            company: RemoteMapperSupport.firstNonEmpty(dto.company, localizedString("delivery.fallback.pickupPoint")),
            address: RemoteMapperSupport.firstNonEmpty(dto.address, localizedString("common.notProvided")),
            state: DeliveryOrderState(rawValue: RemoteMapperSupport.int(dto.state)) ?? .pending,
            remarks: RemoteMapperSupport.firstNonEmpty(dto.remarks),
            orderTime: RemoteMapperSupport.dateText(dto.orderTime, fallback: localizedString("common.justNow"))
        )
    }

    nonisolated static func mapTrade(_ dto: DeliveryTradeRemoteDTO) -> DeliveryTrade {
        DeliveryTrade(
            tradeID: RemoteMapperSupport.text(dto.tradeId, fallback: UUID().uuidString),
            orderID: RemoteMapperSupport.text(dto.orderId),
            username: RemoteMapperSupport.firstNonEmpty(dto.username, "runner"),
            createTime: RemoteMapperSupport.dateText(dto.createTime, fallback: localizedString("common.justNow")),
            state: RemoteMapperSupport.int(dto.state)
        )
    }

    nonisolated static func mapDetail(_ dto: DeliveryDetailRemoteDTO) -> DeliveryOrderDetail {
        DeliveryOrderDetail(
            order: mapOrder(dto.order),
            detailType: RemoteMapperSupport.int(dto.detailType, fallback: 1),
            trade: dto.trade.map(mapTrade)
        )
    }

    nonisolated static func mapMine(_ dto: DeliveryMineRemoteDTO) -> DeliveryMineSummary {
        DeliveryMineSummary(
            published: (dto.published ?? []).map(mapOrder),
            accepted: (dto.accepted ?? []).map(mapOrder)
        )
    }

    nonisolated static func formFields(for draft: DeliveryDraft) -> [FormFieldValue] {
        [
            FormFieldValue(name: "name", value: draft.name),
            FormFieldValue(name: "number", value: draft.number),
            FormFieldValue(name: "phone", value: draft.phone),
            FormFieldValue(name: "price", value: String(format: "%.2f", draft.price)),
            FormFieldValue(name: "company", value: draft.company),
            FormFieldValue(name: "address", value: draft.address),
            FormFieldValue(name: "remarks", value: draft.remarks)
        ]
    }
}
