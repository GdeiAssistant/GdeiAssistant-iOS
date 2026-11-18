import Foundation
import Combine

@MainActor
final class PublishMarketplaceViewModel: ObservableObject {
    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

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
        MarketplaceFormValidator.isFormValid(
            title: title,
            priceText: priceText,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            hasImages: !images.isEmpty
        )
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
        switch MarketplaceFormValidator.validate(
            title: title,
            priceText: priceText,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            phone: phone,
            hasImages: !images.isEmpty,
            requireImages: true
        ) {
        case .failure(let error):
            submitState = .failure(error.message)
            return nil
        case .success(let fields):
            let extraTags = tagsText
                .split(separator: " ")
                .map { String($0) }
                .filter { !$0.isEmpty }
            let typeName = MarketplaceRemoteMapper.displayName(forType: selectedTypeID)

            submitState = .idle

            return MarketplaceDraft(
                title: fields.title,
                price: fields.price,
                summary: RemoteMapperSupport.truncated(fields.description, limit: 28),
                condition: typeName,
                description: fields.description,
                location: fields.location,
                tags: Array(Set([typeName] + extraTags)),
                typeID: selectedTypeID,
                qq: fields.qq,
                phone: fields.phone,
                images: images
            )
        }
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
        selectedTypeID = detail.item.typeID ?? 0
        location = detail.item.location
        qq = detail.qq ?? ""
        phone = detail.phone ?? ""
    }

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    var typeOptions: [String] {
        MarketplaceRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        MarketplaceFormValidator.isFormValid(
            title: title,
            priceText: priceText,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            hasImages: true
        )
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func buildDraft() -> MarketplaceUpdateDraft? {
        switch MarketplaceFormValidator.validate(
            title: title,
            priceText: priceText,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            phone: phone,
            hasImages: true,
            requireImages: false
        ) {
        case .failure(let error):
            submitState = .failure(error.message)
            return nil
        case .success(let fields):
            submitState = .idle

            return MarketplaceUpdateDraft(
                title: fields.title,
                price: fields.price,
                description: fields.description,
                location: fields.location,
                typeID: selectedTypeID,
                qq: fields.qq,
                phone: fields.phone
            )
        }
    }
}
