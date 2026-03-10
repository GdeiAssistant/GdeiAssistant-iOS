import Foundation

struct CommunityTopic: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
}
