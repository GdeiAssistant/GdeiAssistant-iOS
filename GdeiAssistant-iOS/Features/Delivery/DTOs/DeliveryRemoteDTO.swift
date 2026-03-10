import Foundation

struct DeliveryOrderRemoteDTO: Decodable {
    let orderId: RemoteFlexibleString?
    let username: String?
    let orderTime: RemoteFlexibleString?
    let name: String?
    let number: String?
    let phone: String?
    let price: RemoteFlexibleString?
    let company: String?
    let address: String?
    let state: RemoteFlexibleString?
    let remarks: String?
}

struct DeliveryTradeRemoteDTO: Decodable {
    let tradeId: RemoteFlexibleString?
    let orderId: RemoteFlexibleString?
    let createTime: RemoteFlexibleString?
    let username: String?
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
