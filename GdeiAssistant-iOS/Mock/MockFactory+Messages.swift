import Foundation

extension MockFactory {
    static func makeNotifications() -> [AppNotificationItem] {
        MockSeedData.notifications
    }

    static func makeAnnouncementDetailsByID() -> [String: AnnouncementDetailItem] {
        MockSeedData.announcementDetailsByID
    }
}
