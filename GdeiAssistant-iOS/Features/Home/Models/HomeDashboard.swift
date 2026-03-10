import Foundation

struct HomeQuickAction: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
}

struct HomeDashboard: Codable {
    let greeting: String
    let reminderText: String
    let quickActions: [HomeQuickAction]
    let recentItems: [String]
    let campusBannerTitle: String
    let trendingTopics: [String]
}
