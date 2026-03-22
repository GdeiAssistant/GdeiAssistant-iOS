import Foundation
import Combine

@MainActor
final class DeliveryViewModel: ObservableObject {
    @Published var orders: [DeliveryOrder] = []
    @Published var mine = DeliveryMineSummary(published: [], accepted: [])
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionMessage: String?

    private let repository: any DeliveryRepository
    private let pageSize = 20

    init(repository: any DeliveryRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard orders.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let listTask = repository.fetchOrders(start: 0, size: pageSize)
            async let mineTask = repository.fetchMine()
            orders = try await listTask
            mine = try await mineTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "跑腿列表加载失败"
        }
    }

    func refreshMine() async {
        do {
            mine = try await repository.fetchMine()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "我的跑腿刷新失败"
        }
    }

    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail {
        try await repository.fetchDetail(orderID: orderID)
    }

    func accept(orderID: String) async throws {
        try await repository.accept(orderID: orderID)
        actionMessage = "接单成功"
        await refresh()
    }

    func finishTrade(tradeID: String) async throws {
        try await repository.finishTrade(tradeID: tradeID)
        actionMessage = "订单已完成"
        await refresh()
    }
}

@MainActor
final class PublishDeliveryViewModel: ObservableObject {
    @Published var pickupPlace = ""
    @Published var pickupNumber = ""
    @Published var phone = ""
    @Published var rewardText = ""
    @Published var address = ""
    @Published var remarks = ""
    @Published var submitState: SubmitState = .idle

    private let repository: any DeliveryRepository

    init(repository: any DeliveryRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(pickupPlace) &&
        FormValidationSupport.hasText(phone) &&
        FormValidationSupport.hasText(address) &&
        FormValidationSupport.parsePositiveAmount(rewardText, max: 99, message: "") != nil
    }

    func submit() async -> Bool {
        let trimmedPickupPlace = FormValidationSupport.trimmed(pickupPlace)
        let trimmedPickupNumber = FormValidationSupport.trimmed(pickupNumber)
        let trimmedPhone = FormValidationSupport.trimmed(phone)
        let trimmedAddress = FormValidationSupport.trimmed(address)
        let trimmedRemarks = FormValidationSupport.trimmed(remarks)

        if let message = FormValidationSupport.requireText(trimmedPickupPlace, message: "请输入取件地点") {
            submitState = .failure(message)
            return false
        }
        if trimmedPickupPlace.count > 10 {
            submitState = .failure("取件地点不能超过 10 个字")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedPhone, message: "请输入联系电话") {
            submitState = .failure(message)
            return false
        }
        if trimmedPhone.count > 11 {
            submitState = .failure("联系电话不能超过 11 位")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedAddress, message: "请输入送达地址") {
            submitState = .failure(message)
            return false
        }
        if trimmedAddress.count > 50 {
            submitState = .failure("送达地址不能超过 50 个字")
            return false
        }
        guard let reward = FormValidationSupport.parsePositiveAmount(rewardText, max: 99, message: "") else {
            submitState = .failure("请输入有效的跑腿费")
            return false
        }
        if trimmedRemarks.count > 100 {
            submitState = .failure("备注不能超过 100 个字")
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: DeliveryDraft(
                    name: AppConstants.Delivery.defaultTaskName,
                    number: trimmedPickupNumber.isEmpty ? AppConstants.Delivery.defaultPickupCode : trimmedPickupNumber,
                    phone: trimmedPhone,
                    price: reward,
                    company: trimmedPickupPlace,
                    address: trimmedAddress,
                    remarks: trimmedRemarks
                )
            )
            submitState = .success("跑腿任务已发布")
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
            return false
        }
    }
}
