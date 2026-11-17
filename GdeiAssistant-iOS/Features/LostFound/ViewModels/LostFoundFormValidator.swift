import Foundation

struct ValidatedLostFoundFields: Equatable {
    let title: String
    let description: String
    let location: String
    let qq: String?
    let wechat: String?
    let phone: String?
}

struct LostFoundValidationFailure: Error, Equatable {
    let message: String
}

enum LostFoundFormValidator {
    nonisolated static func isFormValid(
        title: String,
        descriptionText: String,
        location: String,
        qq: String,
        wechat: String,
        phone: String,
        hasImages: Bool
    ) -> Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.requireOneFilled([qq, wechat, phone], message: "") == nil &&
        hasImages
    }

    nonisolated static func validate(
        title: String,
        descriptionText: String,
        location: String,
        qq: String,
        wechat: String,
        phone: String,
        hasImages: Bool,
        requireImages: Bool
    ) -> Result<ValidatedLostFoundFields, LostFoundValidationFailure> {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedWechat = FormValidationSupport.trimmed(wechat)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("lostFound.vm.enterItemName")) {
            return .failure(LostFoundValidationFailure(message: message))
        }
        if trimmedTitle.count > 25 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.itemNameTooLong")))
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("lostFound.vm.enterDescription")) {
            return .failure(LostFoundValidationFailure(message: message))
        }
        if trimmedDescription.count > 100 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.descriptionTooLong")))
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("lostFound.vm.enterLocation")) {
            return .failure(LostFoundValidationFailure(message: message))
        }
        if trimmedLocation.count > 30 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.locationTooLong")))
        }
        if let message = FormValidationSupport.requireOneFilled([trimmedQQ, trimmedWechat, trimmedPhone], message: localizedString("lostFound.vm.contactRequired")) {
            return .failure(LostFoundValidationFailure(message: message))
        }
        if !trimmedQQ.isEmpty && trimmedQQ.count > 20 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.qqTooLong")))
        }
        if !trimmedWechat.isEmpty && trimmedWechat.count > 20 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.wechatTooLong")))
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.phoneTooLong")))
        }
        if requireImages && !hasImages {
            return .failure(LostFoundValidationFailure(message: localizedString("lostFound.vm.uploadAtLeastOne")))
        }

        return .success(
            ValidatedLostFoundFields(
                title: trimmedTitle,
                description: trimmedDescription,
                location: trimmedLocation,
                qq: trimmedQQ.isEmpty ? nil : trimmedQQ,
                wechat: trimmedWechat.isEmpty ? nil : trimmedWechat,
                phone: trimmedPhone.isEmpty ? nil : trimmedPhone
            )
        )
    }
}
