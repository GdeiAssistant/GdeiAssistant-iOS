import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: PostDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                DSLoadingView(text: localizedString("community.postDetail.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.detail == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadDetail() }
                }
            } else if let detail = viewModel.detail {
                content(detail)
            } else {
                DSEmptyStateView(icon: "doc.text", title: localizedString("community.postDetail.emptyTitle"), message: localizedString("community.postDetail.emptyMessage"))
            }
        }
        .navigationTitle(LocalizedStringKey("community.postDetail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func content(_ detail: CommunityPostDetail) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: detail.post.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                            .foregroundStyle(DSColor.primary)
                            .accessibilityHidden(true)

                        if !detail.post.isAnonymous, let authorId = detail.post.authorId {
                            NavigationLink {
                                SocialPublicProfileRoute(userID: authorId)
                            } label: {
                                Text(detail.post.authorName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.primary)
                            }
                        } else {
                            Text(detail.post.isAnonymous ? localizedString("community.anonymousStudent") : detail.post.authorName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.title)
                        }

                        Spacer()
                        Text(detail.post.createdAt)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(DSColor.tertiaryText)
                    }

                    Text(detail.post.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DSColor.title)

                    Text(detail.content)
                        .font(.body)
                        .foregroundStyle(DSColor.title)
                }
            }

            if !detail.topics.isEmpty {
                Section {
                    ForEach(detail.topics) { topic in
                        NavigationLink {
                            TopicFeedView(viewModel: container.makeTopicFeedViewModel(topicID: topic.id))
                        } label: {
                            Text(topic.title)
                        }
                    }
                }
            }

            Section {
                Button {
                    Task { await viewModel.toggleLike() }
                } label: {
                    Label(
                        "\(detail.post.likeCount)",
                        systemImage: detail.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
                    )
                    .monospacedDigit()
                    .foregroundStyle(detail.isLiked ? DSColor.primary : DSColor.title)
                }
                .accessibilityAddTraits(detail.isLiked ? .isSelected : [])

                LabeledContent {
                    Text("\(detail.post.commentCount)")
                        .monospacedDigit()
                } label: {
                    Label(localizedString("community.postDetail.commentsSection"), systemImage: "bubble.left")
                }
            }

            Section {
                TextField(
                    LocalizedStringKey("community.postDetail.commentPlaceholder"),
                    text: $viewModel.commentText,
                    axis: .vertical
                )
                .lineLimit(2...4)

                Button(localizedString("community.postDetail.send")) {
                    Task { await viewModel.submitComment() }
                }
                .disabled(viewModel.isSubmittingComment || viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text(LocalizedStringKey("community.postDetail.commentsSection"))
            }

            Section {
                if viewModel.comments.isEmpty {
                    Text(LocalizedStringKey("community.postDetail.noComments"))
                        .foregroundStyle(DSColor.subtitle)
                } else {
                    ForEach(viewModel.comments) { comment in
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            HStack {
                                Text(comment.isAnonymous ? localizedString("community.anonymousUser") : comment.authorName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.title)
                                Spacer()
                                Text(comment.createdAt)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(DSColor.tertiaryText)
                            }
                            Text(comment.content)
                                .font(.body)
                                .foregroundStyle(DSColor.title)
                        }
                        .padding(.vertical, DSSpacing.xxs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .refreshable {
            await viewModel.loadDetail()
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        PostDetailView(viewModel: PostDetailViewModel(postID: "post_hot_001", repository: MockCommunityRepository()))
            .environmentObject(container)
    }
}
