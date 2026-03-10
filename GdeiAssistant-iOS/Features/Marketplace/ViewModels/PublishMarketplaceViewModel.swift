import Foundation
import Combine

@MainActor
final class PublishMarketplaceViewModel: ObservableObject {
    @Published var title = ""
    @Published var priceText = ""
    @Published var descriptionText = ""
    @Published var selectedTypeID = 0
    @Published var location = ""
    @Published var qq = ""
    @Published var phone = ""
    @Published var tagsText = ""
    @Published var images: [UploadImageAsset] = []
    @Published var submitState: SubmitState = .idle

    var typeOptions: [String] {
        MarketplaceRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") != nil &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.hasText(qq) &&
        !images.isEmpty
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func addImage(_ image: UploadImageAsset) {
        guard images.count < 4 else {
            submitState = .failure("最多只能选择 4 张图片")
            return
        }
        images.append(image)
        if case .failure = submitState {
            submitState = .idle
        }
    }

    func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    func buildDraft() -> MarketplaceDraft? {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: "请填写商品名称") {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure("商品名称不能超过 25 个字")
            return nil
        }
        guard let price = FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") else {
            submitState = .failure("请填写有效的商品价格")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: "请填写商品描述") {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure("商品描述不能超过 100 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: "请填写交易地点") {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure("交易地点不能超过 30 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedQQ, message: "请填写 QQ 号") {
            submitState = .failure(message)
            return nil
        }
        if trimmedQQ.count > 20 {
            submitState = .failure("QQ 号不能超过 20 位")
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure("手机号不能超过 11 位")
            return nil
        }
        if images.isEmpty {
            submitState = .failure("请至少选择一张商品图片")
            return nil
        }

        let extraTags = tagsText
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
        let typeName = MarketplaceRemoteMapper.displayName(forType: selectedTypeID)

        submitState = .idle

        return MarketplaceDraft(
            title: trimmedTitle,
            price: price,
            summary: RemoteMapperSupport.truncated(trimmedDescription, limit: 28),
            condition: typeName,
            description: trimmedDescription,
            location: trimmedLocation,
            tags: Array(Set([typeName] + extraTags)),
            typeID: selectedTypeID,
            qq: trimmedQQ,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            images: images
        )
    }
}

@MainActor
final class EditMarketplaceViewModel: ObservableObject {
    let itemID: String
    @Published var title: String
    @Published var priceText: String
    @Published var descriptionText: String
    @Published var selectedTypeID: Int
    @Published var location: String
    @Published var qq: String
    @Published var phone: String
    @Published var submitState: SubmitState = .idle

    init(detail: MarketplaceDetail) {
        itemID = detail.id
        title = detail.item.title
        priceText = String(format: "%.2f", detail.item.price)
        descriptionText = detail.description
        selectedTypeID = MarketplaceRemoteMapper.itemTypes.firstIndex(of: detail.condition) ?? 0
        location = detail.item.location
        qq = Self.extractContactValue(from: detail.contactHint, prefix: "QQ：") ?? ""
        phone = Self.extractContactValue(from: detail.contactHint, prefix: "手机号：") ?? ""
    }

    var typeOptions: [String] {
        MarketplaceRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") != nil &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.hasText(qq)
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func buildDraft() -> MarketplaceUpdateDraft? {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: "请填写商品名称") {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure("商品名称不能超过 25 个字")
            return nil
        }
        guard let price = FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") else {
            submitState = .failure("请填写有效的商品价格")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: "请填写商品描述") {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure("商品描述不能超过 100 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: "请填写交易地点") {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure("交易地点不能超过 30 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedQQ, message: "请填写 QQ 号") {
            submitState = .failure(message)
            return nil
        }
        if trimmedQQ.count > 20 {
            submitState = .failure("QQ 号不能超过 20 位")
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure("手机号不能超过 11 位")
            return nil
        }

        submitState = .idle

        return MarketplaceUpdateDraft(
            title: trimmedTitle,
            price: price,
            description: trimmedDescription,
            location: trimmedLocation,
            typeID: selectedTypeID,
            qq: trimmedQQ,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )
    }

    private static func extractContactValue(from hint: String, prefix: String) -> String? {
        hint
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { $0.hasPrefix(prefix) })
            .map { String($0.dropFirst(prefix.count)) }
    }
}
