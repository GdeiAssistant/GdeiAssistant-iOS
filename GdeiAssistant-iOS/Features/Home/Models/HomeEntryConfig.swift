import Foundation

enum HomeSection: String, CaseIterable, Identifiable {
    case campusServices
    case campusLife

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campusServices:
            return localizedString("home.campusServices")
        case .campusLife:
            return localizedString("home.campusLife")
        }
    }

    var subtitle: String {
        switch self {
        case .campusServices:
            return localizedString("home.campusServicesSubtitle")
        case .campusLife:
            return localizedString("home.campusLifeSubtitle")
        }
    }
}

struct HomeEntryConfig: Identifiable, Hashable {
    var id: String { destination.featureID }

    let title: String
    let subtitle: String
    let icon: String
    let destination: AppDestination
}

struct HomeEntrySection: Identifiable, Hashable {
    let section: HomeSection
    let entries: [HomeEntryConfig]

    var id: String { section.id }
}

extension HomeEntryConfig {
    init(destination: AppDestination, subtitleKey: String) {
        self.title = destination.title
        self.subtitle = localizedString(subtitleKey)
        self.icon = destination.icon
        self.destination = destination
    }

    static let campusServices: [HomeEntryConfig] = [
        HomeEntryConfig(destination: .grade, subtitleKey: "homeEntry.grade.subtitle"),
        HomeEntryConfig(destination: .schedule, subtitleKey: "homeEntry.schedule.subtitle"),
        HomeEntryConfig(destination: .cet, subtitleKey: "homeEntry.cet.subtitle"),
        HomeEntryConfig(destination: .graduateExam, subtitleKey: "homeEntry.graduateExam.subtitle"),
        HomeEntryConfig(destination: .spare, subtitleKey: "homeEntry.spare.subtitle"),
        HomeEntryConfig(destination: .library, subtitleKey: "homeEntry.library.subtitle"),
        HomeEntryConfig(destination: .card, subtitleKey: "homeEntry.card.subtitle"),
        HomeEntryConfig(destination: .dataCenter, subtitleKey: "homeEntry.dataCenter.subtitle"),
        HomeEntryConfig(destination: .evaluate, subtitleKey: "homeEntry.evaluate.subtitle")
    ]

    static let campusLife: [HomeEntryConfig] = [
        HomeEntryConfig(destination: .marketplace, subtitleKey: "homeEntry.marketplace.subtitle"),
        HomeEntryConfig(destination: .delivery, subtitleKey: "homeEntry.delivery.subtitle"),
        HomeEntryConfig(destination: .lostFound, subtitleKey: "homeEntry.lostFound.subtitle"),
        HomeEntryConfig(destination: .secret, subtitleKey: "homeEntry.secret.subtitle"),
        HomeEntryConfig(destination: .dating, subtitleKey: "homeEntry.dating.subtitle"),
        HomeEntryConfig(destination: .express, subtitleKey: "homeEntry.express.subtitle"),
        HomeEntryConfig(destination: .topic, subtitleKey: "homeEntry.topic.subtitle"),
        HomeEntryConfig(destination: .photograph, subtitleKey: "homeEntry.photograph.subtitle")
    ]

    static let allSections: [HomeEntrySection] = [
        HomeEntrySection(section: .campusServices, entries: campusServices),
        HomeEntrySection(section: .campusLife, entries: campusLife)
    ]

    static let allEntries: [HomeEntryConfig] = campusServices + campusLife
}
