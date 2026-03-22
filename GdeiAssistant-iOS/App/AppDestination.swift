import Foundation
import SwiftUI

enum AppDestination: Hashable {
    case community
    case topic
    case express
    case delivery
    case photograph
    case schedule
    case grade
    case card
    case library
    case cet
    case evaluate
    case spare
    case graduateExam
    case news
    case dataCenter
    case marketplace
    case lostFound
    case secret
    case dating
}

extension AppDestination {
    var featureID: String {
        switch self {
        case .community:
            return "community"
        case .topic:
            return "topic"
        case .express:
            return "express"
        case .delivery:
            return "delivery"
        case .photograph:
            return "photograph"
        case .schedule:
            return "schedule"
        case .grade:
            return "grade"
        case .card:
            return "card"
        case .library:
            return "library"
        case .cet:
            return "cet"
        case .evaluate:
            return "evaluate"
        case .spare:
            return "spare"
        case .graduateExam:
            return "graduateExam"
        case .news:
            return "news"
        case .dataCenter:
            return "data_center"
        case .marketplace:
            return "marketplace"
        case .lostFound:
            return "lost_found"
        case .secret:
            return "secret"
        case .dating:
            return "dating"
        }
    }

    private var localizationKey: String {
        switch self {
        case .community: return "feature.community"
        case .topic: return "feature.topic"
        case .express: return "feature.express"
        case .delivery: return "feature.delivery"
        case .photograph: return "feature.photograph"
        case .schedule: return "feature.schedule"
        case .grade: return "feature.grade"
        case .card: return "feature.card"
        case .library: return "feature.library"
        case .cet: return "feature.cet"
        case .evaluate: return "feature.evaluate"
        case .spare: return "feature.spare"
        case .graduateExam: return "feature.graduateExam"
        case .news: return "feature.news"
        case .dataCenter: return "feature.dataCenter"
        case .marketplace: return "feature.marketplace"
        case .lostFound: return "feature.lostFound"
        case .secret: return "feature.secret"
        case .dating: return "feature.dating"
        }
    }

    var title: String {
        localizedString(localizationKey)
    }

    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }

    var icon: String {
        switch self {
        case .community:
            return "rectangle.3.group.bubble.left"
        case .topic:
            return "number"
        case .express:
            return "heart.text.square"
        case .delivery:
            return "shippingbox.circle"
        case .photograph:
            return "camera"
        case .schedule:
            return "calendar"
        case .grade:
            return "chart.bar"
        case .card:
            return "creditcard"
        case .library:
            return "books.vertical"
        case .cet:
            return "doc.text.magnifyingglass"
        case .evaluate:
            return "checkmark.seal"
        case .spare:
            return "building.2"
        case .graduateExam:
            return "graduationcap"
        case .news:
            return "newspaper"
        case .dataCenter:
            return "server.rack"
        case .marketplace:
            return "bag"
        case .lostFound:
            return "shippingbox"
        case .secret:
            return "moon.stars"
        case .dating:
            return "person.3"
        }
    }
}
