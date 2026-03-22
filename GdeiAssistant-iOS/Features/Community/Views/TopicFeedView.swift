import SwiftUI

struct TopicFeedView: View {
    @StateObject private var viewModel: TopicFeedViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: TopicFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(LocalizedStringKey("community.sort"), selection: sortBinding) {
                ForEach(CommunityFeedSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top], 16)

            content
        }
        .background(DSColor.background)
        .navigationTitle(viewModel.topic?.title ?? localizedString("community.topicFeed.defaultTitle"))
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            DSLoadingView(text: localizedString("community.topicFeed.loading"))
        } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
            DSErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
        } else if viewModel.posts.isEmpty {
            DSEmptyStateView(icon: "number.circle", title: localizedString("community.topicFeed.emptyTitle"), message: localizedString("community.topicFeed.emptyMessage"))
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    if let topic = viewModel.topic {
                        DSCard {
                            Text(topic.title)
                                .font(.headline)
                                .foregroundStyle(DSColor.title)

                            Text(topic.summary)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink {
                                PostDetailView(viewModel: container.makePostDetailViewModel(postID: post.id))
                            } label: {
                                DSCard {
                                    Text(post.title)
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)

                                    Text(post.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                        .lineLimit(2)

                                    HStack(spacing: 12) {
                                        Label("\(post.likeCount)", systemImage: "hand.thumbsup")
                                        Label("\(post.commentCount)", systemImage: "bubble.left")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    private var sortBinding: Binding<CommunityFeedSort> {
        Binding(
            get: { viewModel.selectedSort },
            set: { newSort in
                Task { await viewModel.changeSort(newSort) }
            }
        )
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        TopicFeedView(viewModel: TopicFeedViewModel(topicID: "技术交流", repository: MockCommunityRepository()))
            .environmentObject(container)
    }
}
