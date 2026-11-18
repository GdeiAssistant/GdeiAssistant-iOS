import Foundation
import Combine

@MainActor
final class PublishLostFoundViewModel: ObservableObject {
    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

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
        LostFoundFormValidator.isFormValid(
            title: title,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            wechat: wechat,
            phone: phone,
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
        switch LostFoundFormValidator.validate(
            title: title,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            wechat: wechat,
            phone: phone,
            hasImages: !images.isEmpty,
            requireImages: true
        ) {
        case .failure(let error):
            submitState = .failure(error.message)
            return nil
        case .success(let fields):
            let contactHint = [
                fields.qq.map { "\(localizedString("lostFound.mapper.contactQQ"))\($0)" },
                fields.wechat.map { "\(localizedString("lostFound.mapper.contactWechat"))\($0)" },
                fields.phone.map { "\(localizedString("lostFound.mapper.contactPhone"))\($0)" }
            ].compactMap { $0 }.joined(separator: " / ")

            submitState = .idle

            return LostFoundDraft(
                title: fields.title,
                type: selectedType,
                itemTypeID: selectedItemTypeID,
                summary: RemoteMapperSupport.truncated(fields.description, limit: 32),
                description: fields.description,
                location: fields.location,
                contactHint: contactHint,
                qq: fields.qq,
                wechat: fields.wechat,
                phone: fields.phone,
                images: images
            )
        }
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
        qq = detail.qq ?? ""
        wechat = detail.wechat ?? ""
        phone = detail.phone ?? ""
    }

    // No actor-bound cleanup. Avoid the iOS 26.2 MainActor isolated-deinit
    // back-deployment crash on synchronous release (swiftlang/swift#87316).
    nonisolated deinit {}

    var itemTypeOptions: [String] {
        LostFoundRemoteMapper.itemTypes
    }

    var isFormValid: Bool {
        LostFoundFormValidator.isFormValid(
            title: title,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            wechat: wechat,
            phone: phone,
            hasImages: true
        )
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func buildDraft() -> LostFoundUpdateDraft? {
        switch LostFoundFormValidator.validate(
            title: title,
            descriptionText: descriptionText,
            location: location,
            qq: qq,
            wechat: wechat,
            phone: phone,
            hasImages: true,
            requireImages: false
        ) {
        case .failure(let error):
            submitState = .failure(error.message)
            return nil
        case .success(let fields):
            submitState = .idle

            return LostFoundUpdateDraft(
                title: fields.title,
                type: selectedType,
                itemTypeID: selectedItemTypeID,
                description: fields.description,
                location: fields.location,
                qq: fields.qq,
                wechat: fields.wechat,
                phone: fields.phone
            )
        }
    }
}
