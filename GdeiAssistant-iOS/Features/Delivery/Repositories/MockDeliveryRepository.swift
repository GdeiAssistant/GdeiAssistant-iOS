import Foundation

@MainActor
final class MockDeliveryRepository: DeliveryRepository {
    private var orders: [DeliveryOrder] = [
        DeliveryOrder(orderID: "delivery_001", username: "gdeiassistant", name: mockLocalizedText(simplifiedChinese: "代收", traditionalChinese: "代收", english: "Parcel pickup", japanese: "代理受取", korean: "대리수령"), pickupCode: "51233444567", contactPhone: "13800138000", price: 4.50, company: mockLocalizedText(simplifiedChinese: "菜鸟驿站", traditionalChinese: "菜鳥驛站", english: "Cainiao Station", japanese: "菜鳥ステーション", korean: "차이냐오 스테이션"), address: mockLocalizedText(simplifiedChinese: "南苑 3 栋 508", traditionalChinese: "南苑 3 棟 508", english: "South Court Bldg 3 Room 508", japanese: "南苑3棟508", korean: "남원 3동 508호"), state: .pending, remarks: mockLocalizedText(simplifiedChinese: "课后再送", traditionalChinese: "課後再送", english: "Deliver after class", japanese: "授業後にお願いします", korean: "수업 후 전달 부탁"), orderTime: mockLocalizedText(simplifiedChinese: "10分钟前", traditionalChinese: "10分鐘前", english: "10 min ago", japanese: "10分前", korean: "10분 전")),
        DeliveryOrder(orderID: "delivery_002", username: "20230018", name: mockLocalizedText(simplifiedChinese: "代收", traditionalChinese: "代收", english: "Parcel pickup", japanese: "代理受取", korean: "대리수령"), pickupCode: "40399881234", contactPhone: "13911112222", price: 6.00, company: mockLocalizedText(simplifiedChinese: "东门快递点", traditionalChinese: "東門快遞點", english: "East Gate Parcel Point", japanese: "東門宅配受取所", korean: "동문 택배 보관소"), address: mockLocalizedText(simplifiedChinese: "北苑 6 栋 203", traditionalChinese: "北苑 6 棟 203", english: "North Court Bldg 6 Room 203", japanese: "北苑6棟203", korean: "북원 6동 203호"), state: .delivering, remarks: mockLocalizedText(simplifiedChinese: "到宿舍楼下联系", traditionalChinese: "到宿舍樓下聯繫", english: "Message me when you arrive downstairs", japanese: "寮の下に着いたら連絡してください", korean: "기숙사 아래 도착하면 연락 주세요"), orderTime: mockLocalizedText(simplifiedChinese: "40分钟前", traditionalChinese: "40分鐘前", english: "40 min ago", japanese: "40分前", korean: "40분 전"))
    ]

    private var accepted: [DeliveryOrder] = [
        DeliveryOrder(orderID: "delivery_003", username: "20230009", name: mockLocalizedText(simplifiedChinese: "代收", traditionalChinese: "代收", english: "Parcel pickup", japanese: "代理受取", korean: "대리수령"), pickupCode: "30011223344", contactPhone: "13700001111", price: 5.00, company: mockLocalizedText(simplifiedChinese: "菜鸟驿站", traditionalChinese: "菜鳥驛站", english: "Cainiao Station", japanese: "菜鳥ステーション", korean: "차이냐오 스테이션"), address: mockLocalizedText(simplifiedChinese: "教学楼 B201", traditionalChinese: "教學樓 B201", english: "Teaching Building B201", japanese: "講義棟B201", korean: "강의동 B201"), state: .delivering, remarks: mockLocalizedText(simplifiedChinese: "上课前送到", traditionalChinese: "上課前送到", english: "Please deliver before class", japanese: "授業前に届けてください", korean: "수업 전에 전달 부탁"), orderTime: mockLocalizedText(simplifiedChinese: "今天 09:20", traditionalChinese: "今天 09:20", english: "Today 09:20", japanese: "今日 09:20", korean: "오늘 09:20")),
        DeliveryOrder(orderID: "delivery_004", username: "20230025", name: mockLocalizedText(simplifiedChinese: "代拿", traditionalChinese: "代拿", english: "Pickup help", japanese: "代理受け取り", korean: "대리 픽업"), pickupCode: "99001122334", contactPhone: "13600001234", price: 7.00, company: mockLocalizedText(simplifiedChinese: "北门驿站", traditionalChinese: "北門驛站", english: "North Gate Station", japanese: "北門ステーション", korean: "북문 스테이션"), address: mockLocalizedText(simplifiedChinese: "北苑 8 栋 101", traditionalChinese: "北苑 8 棟 101", english: "North Court Bldg 8 Room 101", japanese: "北苑8棟101", korean: "북원 8동 101호"), state: .completed, remarks: mockLocalizedText(simplifiedChinese: "放到宿舍阿姨处即可", traditionalChinese: "放到宿舍阿姨處即可", english: "You can leave it with the dorm manager", japanese: "寮の管理員さんに預けてください", korean: "기숙사 관리실에 맡겨도 됩니다"), orderTime: mockLocalizedText(simplifiedChinese: "昨天 18:40", traditionalChinese: "昨天 18:40", english: "Yesterday 18:40", japanese: "昨日 18:40", korean: "어제 18:40"))
    ]

    private var publishedTradesByOrderID: [String: DeliveryTrade] = [
        "delivery_002": DeliveryTrade(tradeID: "trade_001", orderID: "delivery_002", username: "runner_a", createTime: mockLocalizedText(simplifiedChinese: "22分钟前", traditionalChinese: "22分鐘前", english: "22 min ago", japanese: "22分前", korean: "22분 전"), state: 0)
    ]

    private var acceptedTradesByOrderID: [String: DeliveryTrade] = [
        "delivery_003": DeliveryTrade(tradeID: "trade_002", orderID: "delivery_003", username: "me", createTime: mockLocalizedText(simplifiedChinese: "今天 09:25", traditionalChinese: "今天 09:25", english: "Today 09:25", japanese: "今日 09:25", korean: "오늘 09:25"), state: 0),
        "delivery_004": DeliveryTrade(tradeID: "trade_004", orderID: "delivery_004", username: "me", createTime: mockLocalizedText(simplifiedChinese: "昨天 18:55", traditionalChinese: "昨天 18:55", english: "Yesterday 18:55", japanese: "昨日 18:55", korean: "어제 18:55"), state: 1)
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
                detailType: 0,
                trade: publishedTradesByOrderID[orderID]
            )
        }
        if let order = accepted.first(where: { $0.orderID == orderID }) {
            return DeliveryOrderDetail(order: order, detailType: 3, trade: acceptedTradesByOrderID[orderID])
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
                orderTime: mockLocalizedText(simplifiedChinese: "刚刚", traditionalChinese: "剛剛", english: "Just now", japanese: "たった今", korean: "방금 전")
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
        let trade = DeliveryTrade(tradeID: "trade_mock_\(UUID().uuidString)", orderID: orderID, username: "me", createTime: mockLocalizedText(simplifiedChinese: "刚刚", traditionalChinese: "剛剛", english: "Just now", japanese: "たった今", korean: "방금 전"), state: 0)
        publishedTradesByOrderID[orderID] = trade
        acceptedTradesByOrderID[orderID] = trade
    }

    func finishTrade(tradeID: String) async throws {
        if let orderIndex = orders.firstIndex(where: { publishedTradesByOrderID[$0.orderID]?.tradeID == tradeID }) {
            let order = orders[orderIndex]
            let updated = DeliveryOrder(orderID: order.orderID, username: order.username, name: order.name, pickupCode: order.pickupCode, contactPhone: order.contactPhone, price: order.price, company: order.company, address: order.address, state: .completed, remarks: order.remarks, orderTime: order.orderTime)
            orders[orderIndex] = updated
        }

        if let orderIndex = accepted.firstIndex(where: { acceptedTradesByOrderID[$0.orderID]?.tradeID == tradeID }) {
            let order = accepted[orderIndex]
            let updated = DeliveryOrder(orderID: order.orderID, username: order.username, name: order.name, pickupCode: order.pickupCode, contactPhone: order.contactPhone, price: order.price, company: order.company, address: order.address, state: .completed, remarks: order.remarks, orderTime: order.orderTime)
            accepted[orderIndex] = updated
        }
    }
}
