import Foundation

extension MockFactory {
    static func makeNotifications() -> [AppNotificationItem] {
        MockSeedData.notifications
    }

    static func makeInteractionThreads() -> [InteractionThreadItem] {
        MockSeedData.interactionThreads
    }
}
