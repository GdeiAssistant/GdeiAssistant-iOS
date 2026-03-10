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
                DSLoadingView(text: "正在加载帖子详情...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.detail == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadDetail() }
                }
            } else if let detail = viewModel.detail {
                content(detail)
            } else {
                DSEmptyStateView(icon: "doc.text", title: "暂无帖子详情", message: "请稍后重试")
            }
        }
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func content(_ detail: CommunityPostDetail) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                DSCard {
                    HStack(alignment: .top) {
                        Image(systemName: detail.post.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(DSColor.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(detail.post.isAnonymous ? "匿名同学" : detail.post.authorName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.title)

                            Text(detail.post.createdAt)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }

                        Spacer()
                    }

                    Text(detail.post.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DSColor.title)

                    Text(detail.content)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.title)
                        .lineSpacing(5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detail.topics) { topic in
                                NavigationLink {
                                    TopicFeedView(viewModel: container.makeTopicFeedViewModel(topicID: topic.id))
                                } label: {
                                    Text(topic.title)
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
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await viewModel.toggleLike() }
                        } label: {
                            Label(
                                "\(detail.post.likeCount)",
                                systemImage: detail.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
                            )
                            .font(.subheadline)
                            .foregroundStyle(detail.isLiked ? DSColor.primary : DSColor.subtitle)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Label("\(detail.post.commentCount)", systemImage: "bubble.left")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    }
                }

                DSCard {
                    Text("评论区")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    commentInput

                    if viewModel.comments.isEmpty {
                        Text("还没有评论，欢迎抢先发言。")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(comment.isAnonymous ? "匿名用户" : comment.authorName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DSColor.title)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }

                                Text(comment.content)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.title)

                                Label("\(comment.likeCount)", systemImage: "hand.thumbsup")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.loadDetail()
        }
    }

    private var commentInput: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("写下你的评论...", text: $viewModel.commentText, axis: .vertical)
                .lineLimit(2...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            DSButton(
                title: "发送",
                variant: .primary,
                isLoading: viewModel.isSubmittingComment,
                isDisabled: viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task { await viewModel.submitComment() }
            }
            .frame(width: 92)
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
