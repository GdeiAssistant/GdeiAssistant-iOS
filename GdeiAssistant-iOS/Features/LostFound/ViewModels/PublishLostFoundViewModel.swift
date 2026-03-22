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
            submitState = .failure(localizedString("lostFound.vm.maxImages"))
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

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("lostFound.vm.enterItemName")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure(localizedString("lostFound.vm.itemNameTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("lostFound.vm.enterDescription")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure(localizedString("lostFound.vm.descriptionTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("lostFound.vm.enterLocation")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure(localizedString("lostFound.vm.locationTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireOneFilled([trimmedQQ, trimmedWechat, trimmedPhone], message: localizedString("lostFound.vm.contactRequired")) {
            submitState = .failure(message)
            return nil
        }
        if !trimmedQQ.isEmpty && trimmedQQ.count > 20 {
            submitState = .failure(localizedString("lostFound.vm.qqTooLong"))
            return nil
        }
        if !trimmedWechat.isEmpty && trimmedWechat.count > 20 {
            submitState = .failure(localizedString("lostFound.vm.wechatTooLong"))
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure(localizedString("lostFound.vm.phoneTooLong"))
            return nil
        }
        if images.isEmpty {
            submitState = .failure(localizedString("lostFound.vm.uploadAtLeastOne"))
            return nil
        }

        let contactHint = [
            trimmedQQ.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactQQ"))\(trimmedQQ)",
            trimmedWechat.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactWechat"))\(trimmedWechat)",
            trimmedPhone.isEmpty ? nil : "\(localizedString("lostFound.mapper.contactPhone"))\(trimmedPhone)"
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
        qq = Self.extractContactValue(from: detail.contactHint, prefix: localizedString("lostFound.mapper.contactQQ")) ?? ""
        wechat = Self.extractContactValue(from: detail.contactHint, prefix: localizedString("lostFound.mapper.contactWechat")) ?? ""
        phone = Self.extractContactValue(from: detail.contactHint, prefix: localizedString("lostFound.mapper.contactPhone")) ?? ""
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

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("lostFound.vm.enterItemName")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure(localizedString("lostFound.vm.itemNameTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("lostFound.vm.enterDescription")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure(localizedString("lostFound.vm.descriptionTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("lostFound.vm.enterLocation")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure(localizedString("lostFound.vm.locationTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireOneFilled([trimmedQQ, trimmedWechat, trimmedPhone], message: localizedString("lostFound.vm.contactRequired")) {
            submitState = .failure(message)
            return nil
        }
        if !trimmedQQ.isEmpty && trimmedQQ.count > 20 {
            submitState = .failure(localizedString("lostFound.vm.qqTooLong"))
            return nil
        }
        if !trimmedWechat.isEmpty && trimmedWechat.count > 20 {
            submitState = .failure(localizedString("lostFound.vm.wechatTooLong"))
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure(localizedString("lostFound.vm.phoneTooLong"))
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
