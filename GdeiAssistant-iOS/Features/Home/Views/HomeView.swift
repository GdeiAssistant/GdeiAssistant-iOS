import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.dashboard == nil {
                    DSLoadingView(text: localizedString("home.loading"))
                } else if viewModel.dashboard == nil, let error = viewModel.errorMessage {
                    DSErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else {
                    contentView
                }
            }
            .navigationTitle(localizedString("home.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    private var contentView: some View {
        List {
            ForEach(HomeEntryConfig.allSections) { section in
                if !section.entries.isEmpty {
                    Section {
                        ForEach(section.entries) { entry in
                            NavigationLink {
                                destinationView(for: entry.destination)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.title)
                                            .font(.body)
                                            .foregroundStyle(DSColor.title)
                                        Text(entry.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(DSColor.subtitle)
                                            .lineLimit(2)
                                    }
                                } icon: {
                                    DSIconTile(systemName: entry.icon)
                                }
                            }
                            .accessibilityIdentifier("home.entry.\(entry.destination.featureID)")
                        }
                    } header: {
                        Text(section.section.title)
                    } footer: {
                        Text(section.section.subtitle)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
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
