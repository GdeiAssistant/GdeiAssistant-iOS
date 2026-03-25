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
            submitState = .failure(localizedString("marketplace.maxImages"))
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

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("marketplace.titleEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure(localizedString("marketplace.titleTooLong"))
            return nil
        }
        guard let price = FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") else {
            submitState = .failure(localizedString("marketplace.invalidPrice"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("marketplace.descEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure(localizedString("marketplace.descTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("marketplace.locationEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure(localizedString("marketplace.locationTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedQQ, message: localizedString("marketplace.qqEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedQQ.count > 20 {
            submitState = .failure(localizedString("marketplace.qqTooLong"))
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure(localizedString("marketplace.phoneTooLong"))
            return nil
        }
        if images.isEmpty {
            submitState = .failure(localizedString("marketplace.imageEmpty"))
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
        qq = Self.extractContactValue(
            from: detail.contactHint,
            prefixes: Self.contactPrefixes(for: "marketplace.contactQQPrefix")
        ) ?? ""
        phone = Self.extractContactValue(
            from: detail.contactHint,
            prefixes: Self.contactPrefixes(for: "marketplace.contactPhonePrefix")
        ) ?? ""
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

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("marketplace.titleEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedTitle.count > 25 {
            submitState = .failure(localizedString("marketplace.titleTooLong"))
            return nil
        }
        guard let price = FormValidationSupport.parsePositiveAmount(priceText, max: 9_999.99, message: "") else {
            submitState = .failure(localizedString("marketplace.invalidPrice"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedDescription, message: localizedString("marketplace.descEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedDescription.count > 100 {
            submitState = .failure(localizedString("marketplace.descTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedLocation, message: localizedString("marketplace.locationEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedLocation.count > 30 {
            submitState = .failure(localizedString("marketplace.locationTooLong"))
            return nil
        }
        if let message = FormValidationSupport.requireText(trimmedQQ, message: localizedString("marketplace.qqEmpty")) {
            submitState = .failure(message)
            return nil
        }
        if trimmedQQ.count > 20 {
            submitState = .failure(localizedString("marketplace.qqTooLong"))
            return nil
        }
        if !trimmedPhone.isEmpty && trimmedPhone.count > 11 {
            submitState = .failure(localizedString("marketplace.phoneTooLong"))
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

    private static func extractContactValue(from hint: String, prefixes: [String]) -> String? {
        hint
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { segment in
                prefixes
                    .first(where: { segment.hasPrefix($0) })
                    .map { prefix in
                        String(segment.dropFirst(prefix.count))
                    }
            }
            .first
    }

    private static func contactPrefixes(for key: String) -> [String] {
        var seen = Set<String>()
        return [
            localizedString(key),
            localizedString(key, locale: "zh-CN"),
            localizedString(key, locale: "en")
        ].filter { prefix in
            seen.insert(prefix).inserted
        }
    }
}
