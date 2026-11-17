import Foundation

struct ValidatedMarketplaceFields: Equatable {
    let title: String
    let price: Double
    let description: String
    let location: String
    let qq: String
    let phone: String?
}

struct MarketplaceValidationFailure: Error, Equatable {
    let message: String
}

enum MarketplaceFormValidator {
    nonisolated static let maxPrice = 9_999.99

    nonisolated static func isFormValid(
        title: String,
        priceText: String,
        descriptionText: String,
        location: String,
        qq: String,
        hasImages: Bool
    ) -> Bool {
        FormValidationSupport.hasText(title) &&
        FormValidationSupport.parsePositiveAmount(priceText, max: maxPrice, message: "") != nil &&
        FormValidationSupport.hasText(descriptionText) &&
        FormValidationSupport.hasText(location) &&
        FormValidationSupport.hasText(qq) &&
        hasImages
    }

    nonisolated static func validate(
        title: String,
        priceText: String,
        descriptionText: String,
        location: String,
        qq: String,
        phone: String,
        hasImages: Bool,
        requireImages: Bool
    ) -> Result<ValidatedMarketplaceFields, MarketplaceValidationFailure> {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedDescription = FormValidationSupport.trimmed(descriptionText)
        let trimmedLocation = FormValidationSupport.trimmed(location)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedPhone = FormValidationSupport.trimmed(phone)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("marketplace.titleEmpty")) {
            return .failure(MarketplaceValidationFailure(message: message))
        }
        if trimmedTitle.count > 25 {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.titleTooLong")))
        }
        guard let price = FormValidationSupport.parsePositiveAmount(priceText, max: maxPrice, message: "") else {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.invalidPrice")))
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("marketplace.descEmpty")) {
            return .failure(MarketplaceValidationFailure(message: message))
        }
        if trimmedDescription.count > 100 {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.descTooLong")))
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("marketplace.locationEmpty")) {
            return .failure(MarketplaceValidationFailure(message: message))
        }
        if trimmedLocation.count > 30 {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.locationTooLong")))
        }
        if let message = FormValidationSupport.requireText(trimmedQQ, message: localizedString("marketplace.qqEmpty")) {
            return .failure(MarketplaceValidationFailure(message: message))
        }
        if trimmedQQ.count > 20 {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.qqTooLong")))
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.phoneTooLong")))
        }
        if requireImages && !hasImages {
            return .failure(MarketplaceValidationFailure(message: localizedString("marketplace.imageEmpty")))
        }

        return .success(
            ValidatedMarketplaceFields(
                title: trimmedTitle,
                price: price,
                description: trimmedDescription,
                location: trimmedLocation,
                qq: trimmedQQ,
                phone: trimmedPhone.isEmpty ? nil : trimmedPhone
            )
        )
    }
}
