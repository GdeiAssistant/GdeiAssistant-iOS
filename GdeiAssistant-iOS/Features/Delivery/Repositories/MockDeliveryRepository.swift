import Foundation

@MainActor
final class MockDeliveryRepository: DeliveryRepository {
    private var orders: [DeliveryOrder] = [
        DeliveryOrder(orderID: "delivery_001", username: "gdeiassistant", name: "代收", pickupCode: "51233444567", contactPhone: "13800138000", price: 4.50, company: "菜鸟驿站", address: "南苑 3 栋 508", state: .pending, remarks: "课后再送", orderTime: "10分钟前"),
        DeliveryOrder(orderID: "delivery_002", username: "20230018", name: "代收", pickupCode: "40399881234", contactPhone: "13911112222", price: 6.00, company: "东门快递点", address: "北苑 6 栋 203", state: .delivering, remarks: "到宿舍楼下联系", orderTime: "40分钟前")
    ]

    private var accepted: [DeliveryOrder] = [
        DeliveryOrder(orderID: "delivery_003", username: "20230009", name: "代收", pickupCode: "30011223344", contactPhone: "13700001111", price: 5.00, company: "菜鸟驿站", address: "教学楼 B201", state: .delivering, remarks: "上课前送到", orderTime: "今天 09:20")
    ]

    func fetchOrders(start: Int, size: Int) async throws -> [DeliveryOrder] {
        Array(orders.dropFirst(start).prefix(size))
    }

    func fetchMine() async throws -> DeliveryMineSummary {
        DeliveryMineSummary(published: orders, accepted: accepted)
    }

    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail {
        if let order = orders.first(where: { $0.orderID == orderID }) {
            return DeliveryOrderDetail(
                order: order,
                detailType: order.state == .completed ? 1 : 0,
                trade: order.state == .delivering ? DeliveryTrade(tradeID: "trade_001", orderID: orderID, username: "runner_a", createTime: "刚刚", state: 0) : nil
            )
        }
        if let order = accepted.first(where: { $0.orderID == orderID }) {
            return DeliveryOrderDetail(order: order, detailType: 3, trade: DeliveryTrade(tradeID: "trade_002", orderID: orderID, username: "me", createTime: "刚刚", state: 0))
        }
        throw NetworkError.noData
    }

    func publish(draft: DeliveryDraft) async throws {
        orders.insert(
            DeliveryOrder(
                orderID: "delivery_mock_\(UUID().uuidString)",
                username: "gdeiassistant",
                name: draft.name,
                pickupCode: draft.number,
                contactPhone: draft.phone,
                price: draft.price,
                company: draft.company,
                address: draft.address,
                state: .pending,
                remarks: draft.remarks,
                orderTime: "刚刚"
            ),
            at: 0
        )
    }

    func accept(orderID: String) async throws {
        guard let index = orders.firstIndex(where: { $0.orderID == orderID }) else { return }
        let order = orders[index]
        let updated = DeliveryOrder(orderID: order.orderID, username: order.username, name: order.name, pickupCode: order.pickupCode, contactPhone: order.contactPhone, price: order.price, company: order.company, address: order.address, state: .delivering, remarks: order.remarks, orderTime: order.orderTime)
        orders[index] = updated
        accepted.insert(updated, at: 0)
    }

    func finishTrade(tradeID: String) async throws {
        guard let index = orders.firstIndex(where: { $0.state == .delivering }) else { return }
        let order = orders[index]
        let updated = DeliveryOrder(orderID: order.orderID, username: order.username, name: order.name, pickupCode: order.pickupCode, contactPhone: order.contactPhone, price: order.price, company: order.company, address: order.address, state: .completed, remarks: order.remarks, orderTime: order.orderTime)
        orders[index] = updated
    }
}
