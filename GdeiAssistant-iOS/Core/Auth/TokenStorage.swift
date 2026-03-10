import Foundation

protocol TokenStorage {
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
}

final class InMemoryTokenStorage: TokenStorage {
    private var token: String?

    func saveToken(_ token: String) throws {
        self.token = token
    }

    func loadToken() throws -> String? {
        token
    }

    func deleteToken() throws {
        token = nil
    }
}
