import Foundation

enum DeliveryOrderState: Int, Codable, Hashable {
    case pending = 0
    case delivering = 1
    case completed = 2

    var title: String {
        switch self {
        case .pending:
            return "待接单"
        case .delivering:
            return "配送中"
        case .completed:
            return "已完成"
        }
    }

    var descriptionText: String {
        switch self {
        case .pending:
            return "任务仍在大厅中，等待同学接单。"
        case .delivering:
            return "订单已被接单，正在进行取件或送达。"
        case .completed:
            return "订单已完成交付。"
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
            return "全部"
        case .pending:
            return "待接单"
        case .delivering:
            return "配送中"
        case .completed:
            return "已完成"
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
            return "我发布的"
        case .accepted:
            return "我接的"
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
            return "全部"
        case .pending:
            return "待接单"
        case .delivering:
            return "配送中"
        case .completed:
            return "已完成"
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
            return "发布者"
        case 3:
            return "接单者"
        default:
            return "大厅访客"
        }
    }

    var canViewSensitiveInfo: Bool {
        detailType == 0 || detailType == 3 || order.state != .pending
    }

    var statusDescription: String {
        switch (order.state, detailType) {
        case (.pending, 0):
            return "订单正在等待同学接单，保持电话畅通即可。"
        case (.pending, 1):
            return "当前仍在大厅中，接单后才能看到完整取件码和联系方式。"
        case (.delivering, 0):
            return "已有同学接单，确认收件后可在这里完成交易。"
        case (.delivering, 3):
            return "你已成功接单，请及时完成取件并送达。"
        case (.completed, _):
            return "这笔订单已经完成，可回看记录。"
        default:
            return order.state.descriptionText
        }
    }

    var displayPickupCode: String {
        guard hasMeaningfulPickupCode else { return "未提供" }
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
