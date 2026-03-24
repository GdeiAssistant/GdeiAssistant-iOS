import Foundation

enum RequestID {
    static func generate() -> String {
        UUID().uuidString.lowercased()
    }
}
