import SwiftUI

struct CommunityFeedView: View {
    @StateObject private var viewModel: CommunityFeedViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: CommunityFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            communityShortcutBar

            Picker("排序", selection: sortBinding) {
                ForEach(CommunityFeedSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top], 16)

            contentView
        }
        .background(DSColor.background)
        .navigationTitle(AppDestination.community.title)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var communityShortcutBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeEntryConfig.campusLife.map(\.destination), id: \.self) { destination in
                    NavigationLink {
                        destinationView(for: destination)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: destination.icon)
                                .font(.subheadline)
                            Text(destination.title)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(DSColor.title)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DSColor.cardBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding([.horizontal, .top], 16)
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

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            DSLoadingView(text: "正在加载发现页内容...")
        } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
            DSErrorStateView(message: errorMessage) {
                Task { await viewModel.loadPosts() }
            }
        } else if viewModel.posts.isEmpty {
            DSEmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "暂无帖子",
                message: "试试切换排序或稍后刷新"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.posts) { post in
                        postCard(post)
                    }
                }
                .padding(16)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func postCard(_ post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                PostDetailView(viewModel: container.makePostDetailViewModel(postID: post.id))
            } label: {
                DSCard {
                    HStack(alignment: .top) {
                        Image(systemName: post.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle")
                            .font(.title2)
                            .foregroundStyle(DSColor.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.isAnonymous ? "匿名同学" : post.authorName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.title)

                            Text(post.createdAt)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }

                        Spacer()
                    }

                    Text(post.title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Text(post.summary)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineLimit(3)

                    HStack(spacing: 16) {
                        Label("\(post.likeCount)", systemImage: "hand.thumbsup")
                        Label("\(post.commentCount)", systemImage: "bubble.left")
                    }
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
                }
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(post.tags, id: \.self) { tag in
                        NavigationLink {
                            TopicFeedView(viewModel: container.makeTopicFeedViewModel(topicID: tag))
                        } label: {
                            Text(tag)
                                .font(.caption)
                                .foregroundStyle(DSColor.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DSColor.primary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
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
        case .reading:
            ReadingView(viewModel: container.makeReadingViewModel())
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
