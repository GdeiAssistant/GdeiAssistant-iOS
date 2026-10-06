import SwiftUI

struct CommunityFeedView: View {
    @StateObject private var viewModel: CommunityFeedViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: CommunityFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                DSLoadingView(text: localizedString("community.feed.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadPosts() }
                }
            } else {
                feedList
            }
        }
        .background(DSColor.background)
        .navigationTitle(AppDestination.community.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var sortBinding: Binding<CommunityFeedSort> {
        Binding(
            get: { viewModel.selectedSort },
            set: { newSort in
                Task {
                    await viewModel.changeSort(newSort)
                }
            }
        )
    }

    private var feedList: some View {
        List {
            Section {
                Picker(LocalizedStringKey("community.sort"), selection: sortBinding) {
                    ForEach(CommunityFeedSort.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                ForEach(HomeEntryConfig.campusLife.map(\.destination), id: \.self) { destination in
                    NavigationLink {
                        destinationView(for: destination)
                    } label: {
                        Label(destination.title, systemImage: destination.icon)
                    }
                }
            } header: {
                Text(localizedString("home.campusLife"))
            }

            if viewModel.posts.isEmpty {
                Section {
                    DSEmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: localizedString("community.feed.emptyTitle"),
                        message: localizedString("community.feed.emptyMessage")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PostDetailView(viewModel: container.makePostDetailViewModel(postID: post.id))
                        } label: {
                            postRow(post)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func postRow(_ post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: post.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                    .foregroundStyle(DSColor.primary)
                    .accessibilityHidden(true)
                Text(post.isAnonymous ? localizedString("community.anonymousStudent") : post.authorName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                Spacer()
                Text(post.createdAt)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(DSColor.tertiaryText)
            }

            Text(post.title)
                .font(.headline)
                .foregroundStyle(DSColor.title)

            Text(post.summary)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .lineLimit(3)

            HStack(spacing: DSSpacing.md) {
                Label("\(post.likeCount)", systemImage: "hand.thumbsup")
                Label("\(post.commentCount)", systemImage: "bubble.left")
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(DSColor.tertiaryText)

            if !post.tags.isEmpty {
                Text(post.tags.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(DSColor.primary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, DSSpacing.xxs)
        .accessibilityElement(children: .combine)
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
        case .marketplace:
            MarketplaceView(viewModel: container.makeMarketplaceViewModel())
        case .lostFound:
            LostFoundView(viewModel: container.makeLostFoundViewModel())
        case .secret:
            SecretView(viewModel: container.makeSecretViewModel())
        case .dating:
            DatingView(viewModel: container.makeDatingViewModel())
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
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return CommunityFeedView(viewModel: CommunityFeedViewModel(repository: MockCommunityRepository()))
        .environmentObject(container)
}
