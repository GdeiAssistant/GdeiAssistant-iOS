import Foundation
import Combine

@MainActor
final class PublishLostFoundViewModel: ObservableObject {
    @Published var title = ""
    @Published var selectedType: LostFoundType = .lost
    @Published var selectedItemTypeID = 0
    @Published var descriptionText = ""
    @Published var location = ""
    @Published var qq = ""
    @Published var wechat = ""
    @Published var phone = ""
    @Published var images: [UploadImageAsset] = []
    @Published var submitState: SubmitState = .idle

    var itemTypeOptions: [String] {
        LostFoundRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.requireOneFilled([qq, wechat, phone], message: "") == nil &&
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

    func buildDraft() -> LostFoundDraft? {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedWechat = FormValidationSupport.trimmed(wechat)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: "请填写物品名称") {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure("物品名称不能超过 25 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: "请填写物品描述") {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure("物品描述不能超过 100 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: "请填写地点") {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure("地点不能超过 30 个字")
            return nil
        }
        if let message = FormValidationSupport.requireOneFilled([trimmedQQ, trimmedWechat, trimmedPhone], message: "联系方式至少填写一项") {
            submitState = .failure(message)
            return nil
        }
        if !trimmedQQ.isEmpty && trimmedQQ.count > 20 {
            submitState = .failure("QQ 号不能超过 20 位")
            return nil
        }
        if !trimmedWechat.isEmpty && trimmedWechat.count > 20 {
            submitState = .failure("微信号不能超过 20 位")
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure("手机号不能超过 11 位")
            return nil
        }
        if images.isEmpty {
            submitState = .failure("请至少上传一张图片")
            return nil
        }

        let contactHint = [
            trimmedQQ.isEmpty ? nil : "QQ：\(trimmedQQ)",
            trimmedWechat.isEmpty ? nil : "微信：\(trimmedWechat)",
            trimmedPhone.isEmpty ? nil : "手机号：\(trimmedPhone)"
        ].compactMap { $0 }.joined(separator: " / ")

        submitState = .idle

        return LostFoundDraft(
            title: trimmedTitle,
            type: selectedType,
            itemTypeID: selectedItemTypeID,
            summary: RemoteMapperSupport.truncated(trimmedDescription, limit: 32),
            description: trimmedDescription,
            location: trimmedLocation,
            contactHint: contactHint,
            qq: trimmedQQ.isEmpty ? nil : trimmedQQ,
            wechat: trimmedWechat.isEmpty ? nil : trimmedWechat,
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            images: images
        )
    }
}

@MainActor
final class EditLostFoundViewModel: ObservableObject {
    let itemID: String
    @Published var title: String
    @Published var selectedType: LostFoundType
    @Published var selectedItemTypeID: Int
    @Published var descriptionText: String
    @Published var location: String
    @Published var qq: String
    @Published var wechat: String
    @Published var phone: String
    @Published var submitState: SubmitState = .idle

    init(detail: LostFoundDetail) {
        itemID = detail.id
        title = detail.item.title
        selectedType = detail.item.type
        selectedItemTypeID = detail.item.itemTypeID
        descriptionText = detail.description
        location = detail.item.location
        qq = Self.extractContactValue(from: detail.contactHint, prefix: "QQ：") ?? ""
        wechat = Self.extractContactValue(from: detail.contactHint, prefix: "微信：") ?? ""
        phone = Self.extractContactValue(from: detail.contactHint, prefix: "手机号：") ?? ""
    }

    var itemTypeOptions: [String] {
        LostFoundRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.requireOneFilled([qq, wechat, phone], message: "") == nil
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func buildDraft() -> LostFoundUpdateDraft? {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedWechat = FormValidationSupport.trimmed(wechat)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: "请填写物品名称") {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure("物品名称不能超过 25 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: "请填写物品描述") {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure("物品描述不能超过 100 个字")
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: "请填写地点") {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure("地点不能超过 30 个字")
            return nil
        }
        if let message = FormValidationSupport.requireOneFilled([trimmedQQ, trimmedWechat, trimmedPhone], message: "联系方式至少填写一项") {
            submitState = .failure(message)
            return nil
        }
        if !trimmedQQ.isEmpty && trimmedQQ.count > 20 {
            submitState = .failure("QQ 号不能超过 20 位")
            return nil
        }
        if !trimmedWechat.isEmpty && trimmedWechat.count > 20 {
            submitState = .failure("微信号不能超过 20 位")
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure("手机号不能超过 11 位")
            return nil
        }

        submitState = .idle

        return LostFoundUpdateDraft(
            title: trimmedTitle,
            type: selectedType,
            itemTypeID: selectedItemTypeID,
            description: trimmedDescription,
            location: trimmedLocation,
            qq: trimmedQQ.isEmpty ? nil : trimmedQQ,
            wechat: trimmedWechat.isEmpty ? nil : trimmedWechat,
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
