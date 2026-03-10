import Foundation

enum SubmitState: Equatable {
    case idle
    case submitting
    case success(String)
    case failure(String)

    var isSubmitting: Bool {
        if case .submitting = self {
            return true
        }
        return false
    }

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var message: String? {
        switch self {
        case .success(let message), .failure(let message):
            return message
        case .idle, .submitting:
            return nil
        }
    }
}
