import Foundation
import Combine

/// Aggregates unread counts from messages sources for the tab bar badge.
@MainActor
final class UnreadBadgeStore: ObservableObject {
    @Published private(set) var totalUnread = 0
    private(set) var sessionRevision = 0

    private var interactionUnread = 0
    private var directMessageUnread = 0

    var badgeText: String? {
        guard totalUnread > 0 else { return nil }
        return totalUnread > 99 ? "99+" : String(totalUnread)
    }

    func updateInteractionUnread(_ count: Int) {
        interactionUnread = max(0, count)
        recomputeTotal()
    }

    func updateDirectMessageUnread(_ count: Int) {
        directMessageUnread = max(0, count)
        recomputeTotal()
    }

    func reset() {
        sessionRevision &+= 1
        interactionUnread = 0
        directMessageUnread = 0
        recomputeTotal()
    }

    private func recomputeTotal() {
        totalUnread = interactionUnread + directMessageUnread
    }
}
