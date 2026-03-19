import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var container: AppContainer

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
                            entries: section.entries,
                            columns: 3,
                            tint: section.section == .campusServices ? DSColor.primary : DSColor.secondary
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
        entries: [HomeEntryConfig],
        columns: Int,
        tint: Color
    ) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns),
                    spacing: 10
                ) {
                    ForEach(entries) { entry in
                        NavigationLink {
                            destinationView(for: entry.destination)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: entry.icon)
                                    .font(.title3)
                                    .foregroundStyle(tint)

                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.title)

                                Text(entry.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
                            .padding(12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            DatingView(viewModel: container.makeDatingCenterViewModel())
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return HomeView(viewModel: HomeViewModel(repository: MockHomeRepository()))
        .environmentObject(container)
}
