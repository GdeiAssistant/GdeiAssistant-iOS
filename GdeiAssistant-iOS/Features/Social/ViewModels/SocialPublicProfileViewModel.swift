import Foundation
import Combine

@MainActor
final class SocialPublicProfileViewModel: ObservableObject {
    @Published private(set) var user: SocialUser?
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var openedConversationID: String?

    let userID: String
    private let repository: any SocialRepository

    init(userID: String, repository: any SocialRepository) {
        self.userID = userID
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            user = try await repository.fetchUser(id: userID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.profile.loadFailed")
        }
    }

    func toggleFollow() async {
        guard let current = user, !current.isSelf else { return }
        isMutating = true
        defer { isMutating = false }
        do {
            user = current.isFollowing
                ? try await repository.unfollow(userID: current.id)
                : try await repository.follow(userID: current.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func toggleBlock() async {
        guard let current = user, !current.isSelf else { return }
        isMutating = true
        defer { isMutating = false }
        do {
            if current.blockedByMe {
                _ = try await repository.unblock(userID: current.id)
            } else {
                _ = try await repository.block(userID: current.id)
            }
            user = try await repository.fetchUser(id: current.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.action.failed")
        }
    }

    func openConversation() async {
        guard let current = user, current.canMessage else {
            infoMessage = localizedString("social.chat.permissionDenied")
            return
        }
        isMutating = true
        defer { isMutating = false }
        do {
            let conversation = try await repository.createConversation(peerID: current.id)
            openedConversationID = conversation.id
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("social.chat.openFailed")
        }
    }
}
