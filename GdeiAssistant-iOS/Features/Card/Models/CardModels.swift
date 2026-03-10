import Foundation

enum CardStatus: String, Codable {
    case normal
    case lost
    case frozen

    var displayName: String {
        switch self {
        case .normal:
            return "正常"
        case .lost:
            return "已挂失"
        case .frozen:
            return "已冻结"
        }
    }
}

struct CampusCardInfo: Codable, Hashable {
    let cardNumber: String
    let ownerName: String
    let balance: Double
    let status: CardStatus
    let lastUpdated: String
}

struct CardTransaction: Codable, Identifiable, Hashable {
    let id: String
    let timeText: String
    let merchantName: String
    let amount: Double
    let category: String
}

struct CampusCardDashboard: Codable {
    let info: CampusCardInfo
    let transactions: [CardTransaction]
}

struct CardLossRequest: Hashable {
    let cardPassword: String
}
