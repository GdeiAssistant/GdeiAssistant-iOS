import SwiftUI

struct TopicFeedView: View {
    @StateObject private var viewModel: TopicFeedViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: TopicFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                DSLoadingView(text: localizedString("community.topicFeed.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                List {
                    if let topic = viewModel.topic {
                        Section {
                            Text(topic.summary)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }

                    Section {
                        Picker(LocalizedStringKey("community.sort"), selection: sortBinding) {
                            ForEach(CommunityFeedSort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        if viewModel.posts.isEmpty {
                            DSEmptyStateView(
                                icon: "number.circle",
                                title: localizedString("community.topicFeed.emptyTitle"),
                                message: localizedString("community.topicFeed.emptyMessage")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.posts) { post in
                                NavigationLink {
                                    PostDetailView(viewModel: container.makePostDetailViewModel(postID: post.id))
                                } label: {
                                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                        Text(post.title)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                        Text(post.summary)
                                            .font(.subheadline)
                                            .foregroundStyle(DSColor.subtitle)
                                            .lineLimit(2)
                                        HStack(spacing: DSSpacing.sm) {
                                            Label("\(post.likeCount)", systemImage: "hand.thumbsup")
                                            Label("\(post.commentCount)", systemImage: "bubble.left")
                                        }
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(DSColor.tertiaryText)
                                    }
                                    .padding(.vertical, DSSpacing.xxs)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .dsListBackground()
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .navigationTitle(viewModel.topic?.title ?? localizedString("community.topicFeed.defaultTitle"))
        .task {
            await viewModel.loadIfNeeded()
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
