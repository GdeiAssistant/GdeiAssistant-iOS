import Foundation

enum DeliveryOrderState: Int, Codable, Hashable {
    case pending = 0
    case delivering = 1
    case completed = 2

    var title: String {
        switch self {
        case .pending:
            return localizedString("delivery.state.pending")
        case .delivering:
            return localizedString("delivery.state.delivering")
        case .completed:
            return localizedString("delivery.state.completed")
        }
    }

    var descriptionText: String {
        switch self {
        case .pending:
            return localizedString("delivery.stateDescription.pending")
        case .delivering:
            return localizedString("delivery.stateDescription.delivering")
        case .completed:
            return localizedString("delivery.stateDescription.completed")
        }
    }
}

enum DeliveryOrderFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case delivering
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return localizedString("marketplace.all")
        case .pending:
            return localizedString("delivery.state.pending")
        case .delivering:
            return localizedString("delivery.state.delivering")
        case .completed:
            return localizedString("delivery.state.completed")
        }
    }
}

enum DeliveryMineTab: String, CaseIterable, Identifiable {
    case published
    case accepted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .published:
            return localizedString("delivery.publishedTab")
        case .accepted:
            return localizedString("delivery.acceptedTab")
        }
    }
}

enum DeliveryMineStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case delivering
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return localizedString("marketplace.all")
        case .pending:
            return localizedString("delivery.state.pending")
        case .delivering:
            return localizedString("delivery.state.delivering")
        case .completed:
            return localizedString("delivery.state.completed")
        }
    }
}

struct DeliveryOrder: Codable, Identifiable, Hashable {
    var id: String { orderID }

    let orderID: String
    let username: String
    let name: String
    let pickupCode: String
    let contactPhone: String
    let price: Double
    let company: String
    let address: String
    let state: DeliveryOrderState
    let remarks: String
    let orderTime: String
}

struct DeliveryTrade: Codable, Hashable {
    let tradeID: String
    let orderID: String
    let username: String
    let createTime: String
    let state: Int
}

struct DeliveryOrderDetail: Codable, Identifiable, Hashable {
    var id: String { order.id }

    let order: DeliveryOrder
    let detailType: Int
    let trade: DeliveryTrade?

    var canAccept: Bool { detailType == 1 && order.state == .pending }
    var canComplete: Bool { detailType == 0 && order.state == .delivering && trade != nil }
    var userRoleTitle: String {
        switch detailType {
        case 0:
            return localizedString("delivery.role.publisher")
        case 3:
            return localizedString("delivery.role.acceptor")
        default:
            return localizedString("delivery.role.visitor")
        }
    }

    var canViewSensitiveInfo: Bool {
        detailType == 0 || detailType == 3 || order.state != .pending
    }

    var statusDescription: String {
        switch (order.state, detailType) {
        case (.pending, 0):
            return localizedString("delivery.statusDescription.pending.publisher")
        case (.pending, 1):
            return localizedString("delivery.statusDescription.pending.visitor")
        case (.delivering, 0):
            return localizedString("delivery.statusDescription.delivering.publisher")
        case (.delivering, 3):
            return localizedString("delivery.statusDescription.delivering.acceptor")
        case (.completed, _):
            return localizedString("delivery.statusDescription.completed")
        default:
            return order.state.descriptionText
        }
    }

    var displayPickupCode: String {
        guard hasMeaningfulPickupCode else { return localizedString("common.notProvided") }
        return canViewSensitiveInfo ? order.pickupCode : masked(order.pickupCode)
    }

    var hasMeaningfulPickupCode: Bool {
        let trimmed = order.pickupCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != AppConstants.Delivery.defaultPickupCode
    }

    var displayContactPhone: String {
        canViewSensitiveInfo ? order.contactPhone : masked(order.contactPhone)
    }

    private func masked(_ text: String) -> String {
        guard text.count > 4 else { return String(repeating: "*", count: max(text.count, 3)) }
        return String(repeating: "*", count: max(text.count - 4, 3)) + text.suffix(4)
    }
}

struct DeliveryMineSummary: Codable, Hashable {
    let published: [DeliveryOrder]
    let accepted: [DeliveryOrder]
}

struct DeliveryDraft: Codable {
    let name: String
    let number: String
    let phone: String
    let price: Double
    let company: String
    let address: String
    let remarks: String
}
