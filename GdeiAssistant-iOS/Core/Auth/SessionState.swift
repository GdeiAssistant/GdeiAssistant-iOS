import Foundation
import Combine

@MainActor
final class SessionState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserProfile?
    @Published var isRestoringSession = true
    @Published var authErrorMessage: String?

    func beginRestoringSession() {
        isRestoringSession = true
    }

    func markLoggedIn(user: UserProfile) {
        currentUser = user
        isLoggedIn = true
        isRestoringSession = false
        authErrorMessage = nil
    }

    func markLoggedOut(message: String? = nil) {
        currentUser = nil
        isLoggedIn = false
        isRestoringSession = false
        authErrorMessage = message
    }
}
