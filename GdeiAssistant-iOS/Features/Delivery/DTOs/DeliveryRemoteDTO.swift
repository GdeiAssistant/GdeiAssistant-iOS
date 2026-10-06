import Foundation

struct DeliveryOrderRemoteDTO: Decodable {
    let orderId: RemoteFlexibleString?
    let displayName: String?
    let orderTime: RemoteFlexibleString?
    let taskName: String?
    let pickupCode: String?
    let contactPhone: String?
    let price: RemoteFlexibleString?
    let pickupLocation: String?
    let deliveryAddress: String?
    let state: RemoteFlexibleString?
    let remarks: String?
}

struct DeliveryTradeRemoteDTO: Decodable {
    let tradeId: RemoteFlexibleString?
    let orderId: RemoteFlexibleString?
    let createTime: RemoteFlexibleString?
    let displayName: String?
    let state: RemoteFlexibleString?
}

struct DeliveryDetailRemoteDTO: Decodable {
    let order: DeliveryOrderRemoteDTO
    let detailType: RemoteFlexibleString?
    let trade: DeliveryTradeRemoteDTO?
}

struct DeliveryMineRemoteDTO: Decodable {
    let published: [DeliveryOrderRemoteDTO]?
    let accepted: [DeliveryOrderRemoteDTO]?
}

struct DeliveryPublishRequest: Encodable {
    let taskName: String
    let pickupCode: String
    let contactPhone: String
    let price: String
    let pickupLocation: String
    let deliveryAddress: String
    let remarks: String
}
