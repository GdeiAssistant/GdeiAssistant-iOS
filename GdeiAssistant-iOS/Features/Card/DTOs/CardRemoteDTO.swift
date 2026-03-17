import Foundation

struct CardQueryRequestDTO: Codable {
    let year: Int
    let month: Int
    let date: Int
}

struct CardLossRemoteDTO: Encodable {
    let cardPassword: String
}

struct CardInfoDTO: Decodable {
    let name: RemoteFlexibleString?
    let number: RemoteFlexibleString?
    let cardBalance: RemoteFlexibleString?
    let cardInterimBalance: RemoteFlexibleString?
    let cardNumber: RemoteFlexibleString?
    let cardLostState: RemoteFlexibleString?
    let cardFreezeState: RemoteFlexibleString?
}

struct CardTransactionDTO: Decodable {
    let tradeTime: RemoteFlexibleString?
    let merchantName: RemoteFlexibleString?
    let tradeName: RemoteFlexibleString?
    let tradePrice: RemoteFlexibleString?
    let accountBalance: RemoteFlexibleString?
}

struct CardQueryResultDTO: Decodable {
    let cardQuery: CardQueryRequestDTO?
    let cardInfo: CardInfoDTO?
    let cardList: [CardTransactionDTO]?
}
