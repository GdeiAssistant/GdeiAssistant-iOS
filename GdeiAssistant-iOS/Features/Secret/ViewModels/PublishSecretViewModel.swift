import Foundation
import Combine

@MainActor
final class PublishSecretViewModel: ObservableObject {
    @Published var mode: SecretDraftMode = .text
    @Published var selectedThemeID = Int.random(in: 1...12)
    @Published var content = ""
    @Published var deleteAfter24Hours = false
    @Published var submitState: SubmitState = .idle

    var themeOptions: [Int] {
        SecretRemoteMapper.themeIDs
    }

    var isFormValid: Bool {
        switch mode {
        case .text:
            return FormValidationSupport.hasText(content)
        case .voice:
            return true
        }
    }

    var failureMessage: String? {
        if case .failure(let message) = submitState {
            return message
        }
        return nil
    }

    func buildDraft(voice: SecretVoiceDraft? = nil) -> SecretDraft? {
        let trimmedContent = FormValidationSupport.trimmed(content)

        if mode == .text {
            if let message = FormValidationSupport.requireText(trimmedContent, message: localizedString("secret.contentEmpty")) {
                submitState = .failure(message)
                return nil
            }
            if trimmedContent.count > 100 {
                submitState = .failure(localizedString("secret.contentTooLong"))
                return nil
            }
        } else if voice == nil {
            submitState = .failure(localizedString("secret.noVoice"))
            return nil
        }

        submitState = .idle

        return SecretDraft(
            title: mode == .text ? RemoteMapperSupport.truncated(trimmedContent, limit: 18) : localizedString("secret.voiceTitle"),
            content: mode == .text ? trimmedContent : nil,
            themeID: selectedThemeID,
            timerEnabled: deleteAfter24Hours,
            mode: mode,
            voice: voice
        )
    }
}
