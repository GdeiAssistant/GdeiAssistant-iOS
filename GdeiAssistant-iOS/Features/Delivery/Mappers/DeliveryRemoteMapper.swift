import Foundation

enum DeliveryRemoteMapper {
    nonisolated static func mapOrder(_ dto: DeliveryOrderRemoteDTO) throws -> DeliveryOrder {
        guard let id = dto.orderId, let value = Int(RemoteMapperSupport.text(id)), value > 0 else {
            throw NetworkError.invalidResponse
        }
        return DeliveryOrder(
            orderID: RemoteMapperSupport.text(dto.orderId, fallback: ""),
            displayName: RemoteMapperSupport.firstNonEmpty(dto.displayName, localizedString("delivery.fallback.campusUser")),
            name: RemoteMapperSupport.firstNonEmpty(dto.taskName, localizedString("delivery.fallback.taskName")),
            pickupCode: RemoteMapperSupport.firstNonEmpty(dto.pickupCode),
            contactPhone: RemoteMapperSupport.firstNonEmpty(dto.contactPhone),
            price: RemoteMapperSupport.double(dto.price),
            company: RemoteMapperSupport.firstNonEmpty(dto.pickupLocation, localizedString("delivery.fallback.pickupPoint")),
            address: RemoteMapperSupport.firstNonEmpty(dto.deliveryAddress, localizedString("common.notProvided")),
            state: DeliveryOrderState(rawValue: RemoteMapperSupport.int(dto.state, fallback: -1)) ?? .unknown,
            remarks: RemoteMapperSupport.firstNonEmpty(dto.remarks),
            orderTime: RemoteMapperSupport.dateText(dto.orderTime, fallback: localizedString("common.justNow"))
        )
    }

    nonisolated static func mapTrade(_ dto: DeliveryTradeRemoteDTO) throws -> DeliveryTrade {
        guard let id = dto.tradeId, let value = Int(RemoteMapperSupport.text(id)), value > 0,
              Int(RemoteMapperSupport.text(dto.orderId)).map({ $0 > 0 }) == true else {
            throw NetworkError.invalidResponse
        }
        return DeliveryTrade(
            tradeID: RemoteMapperSupport.text(dto.tradeId, fallback: ""),
            orderID: RemoteMapperSupport.text(dto.orderId),
            displayName: RemoteMapperSupport.firstNonEmpty(dto.displayName, "runner"),
            createTime: RemoteMapperSupport.dateText(dto.createTime, fallback: localizedString("common.justNow")),
            state: RemoteMapperSupport.int(dto.state, fallback: -1)
        )
    }

    nonisolated static func mapDetail(_ dto: DeliveryDetailRemoteDTO) throws -> DeliveryOrderDetail {
        DeliveryOrderDetail(
            order: try mapOrder(dto.order),
            detailType: RemoteMapperSupport.int(dto.detailType, fallback: 2),
            trade: try dto.trade.map(mapTrade)
        )
    }

    nonisolated static func mapMine(_ dto: DeliveryMineRemoteDTO) throws -> DeliveryMineSummary {
        DeliveryMineSummary(
            published: try (dto.published ?? []).map(mapOrder),
            accepted: try (dto.accepted ?? []).map(mapOrder)
        )
    }

    nonisolated static func publishRequest(for draft: DeliveryDraft) -> DeliveryPublishRequest {
        DeliveryPublishRequest(
            taskName: draft.name, pickupCode: draft.number, contactPhone: draft.phone,
            price: String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), draft.price),
            pickupLocation: draft.company, deliveryAddress: draft.address, remarks: draft.remarks
        )
    }
}
