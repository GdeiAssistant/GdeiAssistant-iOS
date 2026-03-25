import Foundation

enum ProfileSaveResult: Equatable {
    case success
    case failure(message: String)

    static func from(didSave: Bool, errorMessage: String?) -> ProfileSaveResult {
        guard !didSave else {
            return .success
        }

        let trimmedMessage = errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedMessage.isEmpty {
            return .failure(message: localizedString("common.saveFailed"))
        }

        return .failure(message: trimmedMessage)
    }
}
