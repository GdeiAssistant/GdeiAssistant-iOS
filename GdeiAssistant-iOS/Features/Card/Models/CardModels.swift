import Foundation

enum CardStatus: String, Codable {
    case normal
    case lost
    case frozen

    var displayName: String {
        switch self {
        case .normal:
            return localizedString("card.status.normal")
        case .lost:
            return localizedString("card.status.lost")
        case .frozen:
            return localizedString("card.status.frozen")
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
