import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            contentView
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(visibleSections) { section in
                    if !section.entries.isEmpty {
                        sectionCard(
                            section: section.section,
                            entries: section.entries
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
    }

    private var visibleSections: [HomeEntrySection] {
        HomeEntryConfig.allSections
    }

    private func sectionCard(
        section: HomeSection,
        entries: [HomeEntryConfig]
    ) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 16
                ) {
                    ForEach(entries) { entry in
                        NavigationLink {
                            destinationView(for: entry.destination)
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(DSColor.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: entry.icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(DSColor.primary)
                                }

                                Text(entry.title)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                    .foregroundStyle(DSColor.title)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .community:
            CommunityFeedView(viewModel: container.makeCommunityViewModel())
        case .topic:
            TopicView(viewModel: container.makeTopicViewModel())
        case .express:
            ExpressView(viewModel: container.makeExpressViewModel())
        case .delivery:
            DeliveryView(viewModel: container.makeDeliveryViewModel())
        case .photograph:
            PhotographView(viewModel: container.makePhotographViewModel())
        case .schedule:
            ScheduleView(viewModel: container.makeScheduleViewModel())
        case .grade:
            GradeView(viewModel: container.makeGradeViewModel())
        case .card:
            CardView(viewModel: container.makeCardViewModel())
        case .library:
            LibraryView(viewModel: container.makeLibraryViewModel())
        case .cet:
            CETView(viewModel: container.makeCETViewModel())
        case .evaluate:
            EvaluateView(viewModel: container.makeEvaluateViewModel())
        case .spare:
            SpareView(viewModel: container.makeSpareViewModel())
        case .graduateExam:
            GraduateExamView(viewModel: container.makeGraduateExamViewModel())
        case .news:
            NewsView(viewModel: container.makeNewsViewModel())
        case .dataCenter:
            DataCenterView()
        case .marketplace:
            MarketplaceView(viewModel: container.makeMarketplaceViewModel())
        case .lostFound:
            LostFoundView(viewModel: container.makeLostFoundViewModel())
        case .secret:
            SecretView(viewModel: container.makeSecretViewModel())
        case .dating:
            DatingView(viewModel: container.makeDatingViewModel())
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return HomeView(viewModel: HomeViewModel(repository: MockHomeRepository()))
        .environmentObject(container)
}
