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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("delivery.listLoadFailed")
        }
    }

    func refreshMine() async {
        do {
            mine = try await repository.fetchMine()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("delivery.mineRefreshFailed")
        }
    }

    func fetchDetail(orderID: String) async throws -> DeliveryOrderDetail {
        try await repository.fetchDetail(orderID: orderID)
    }

    func accept(orderID: String) async throws {
        try await repository.accept(orderID: orderID)
        actionMessage = localizedString("delivery.acceptSuccess")
        await refresh()
    }

    func finishTrade(tradeID: String) async throws {
        try await repository.finishTrade(tradeID: tradeID)
        actionMessage = localizedString("delivery.orderCompleted")
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

        if let message = FormValidationSupport.requireText(trimmedPickupPlace, message: localizedString("delivery.pickupPlaceRequired")) {
            submitState = .failure(message)
            return false
        }
        if trimmedPickupPlace.count > 10 {
            submitState = .failure(localizedString("delivery.pickupPlaceTooLong"))
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedPhone, message: localizedString("delivery.phoneRequired")) {
            submitState = .failure(message)
            return false
        }
        if trimmedPhone.count > 11 {
            submitState = .failure(localizedString("delivery.phoneTooLong"))
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedAddress, message: localizedString("delivery.addressRequired")) {
            submitState = .failure(message)
            return false
        }
        if trimmedAddress.count > 50 {
            submitState = .failure(localizedString("delivery.addressTooLong"))
            return false
        }
        guard let reward = FormValidationSupport.parsePositiveAmount(rewardText, max: 99, message: "") else {
            submitState = .failure(localizedString("delivery.rewardInvalid"))
            return false
        }
        if trimmedRemarks.count > 100 {
            submitState = .failure(localizedString("delivery.remarksTooLong"))
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
            submitState = .success(localizedString("delivery.published"))
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("delivery.publishFailed"))
            return false
        }
    }
}
