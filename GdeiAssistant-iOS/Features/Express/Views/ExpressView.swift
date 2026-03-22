import SwiftUI

struct ExpressView: View {
    @StateObject private var viewModel: ExpressViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: ExpressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                DSLoadingView(text: localizedString("express.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.posts.isEmpty {
                DSEmptyStateView(icon: "heart.text.square", title: localizedString("express.emptyTitle"), message: localizedString("express.emptyMessage"))
            } else {
                List(viewModel.posts) { post in
                    NavigationLink {
                        ExpressDetailView(viewModel: viewModel, postID: post.id)
                    } label: {
                        ExpressPostRow(post: post)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle(LocalizedStringKey("express.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(LocalizedStringKey("express.mine")) {
                    MyExpressPostsView(viewModel: viewModel)
                }

                NavigationLink(LocalizedStringKey("express.publish")) {
                    PublishExpressView(viewModel: container.makePublishExpressViewModel(), listViewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct ExpressPostRow: View {
    let post: ExpressPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(post.nickname)
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                Text(post.targetName)
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                Spacer()
                Text(post.publishTime)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            }

            Text(post.contentPreview)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .lineLimit(3)

            HStack {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                Label("\(post.commentCount)", systemImage: "bubble.left")
                Text(post.canGuess ? LocalizedStringKey("express.canGuess") : LocalizedStringKey("express.cannotGuess"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((post.canGuess ? DSColor.warning : DSColor.subtitle).opacity(0.12))
                    .foregroundStyle(post.canGuess ? DSColor.warning : DSColor.subtitle)
                    .clipShape(Capsule())
            }
            .font(.caption)
            .foregroundStyle(DSColor.subtitle)
        }
        .padding(.vertical, 6)
    }
}

struct ExpressDetailView: View {
    @ObservedObject var viewModel: ExpressViewModel
    let postID: String
    let notificationTargetType: String?
    let notificationTargetSubID: String?
    let notificationID: String?
    var onPostChanged: ((ExpressPostDetail) -> Void)? = nil

    @State private var detail: ExpressPostDetail?
    @State private var comments: [ExpressCommentItem] = []
    @State private var commentInput = ""
    @State private var guessName = ""
    @State private var resultMessage: String?
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(
        viewModel: ExpressViewModel,
        postID: String,
        notificationTargetType: String? = nil,
        notificationTargetSubID: String? = nil,
        notificationID: String? = nil,
        onPostChanged: ((ExpressPostDetail) -> Void)? = nil
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.postID = postID
        self.notificationTargetType = notificationTargetType
        self.notificationTargetSubID = notificationTargetSubID
        self.notificationID = notificationID
        self.onPostChanged = onPostChanged
    }

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("express.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            if let notificationContextText {
                                Text(notificationContextText)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.primary)
                            }

                            HStack {
                                Text(detail.post.nickname)
                                    .font(.headline)
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                                Text(detail.post.targetName)
                                    .font(.headline)
                                Spacer()
                                Text(detail.post.publishTime)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            HStack(spacing: 18) {
                                statItem(title: localizedString("express.detail.likes"), value: detail.post.likeCount)
                                statItem(title: localizedString("express.detail.comments"), value: detail.post.commentCount)
                                if detail.post.canGuess {
                                    statItem(title: localizedString("express.detail.correctGuess"), value: detail.post.correctGuessCount)
                                }
                            }

                            Text(detail.content)
                                .font(.body)
                                .foregroundStyle(DSColor.title)

                            if detail.post.canGuess {
                                Text(LocalizedStringKey("express.detail.guessHint"))
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            if let realName = detail.realName, detail.post.canGuess {
                                Text(localizedString("express.detail.realName") + realName)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            HStack {
                                Button {
                                    Task { await like() }
                                } label: {
                                    Label(detail.post.isLiked ? LocalizedStringKey("express.detail.liked") : LocalizedStringKey("express.detail.like"), systemImage: detail.post.isLiked ? "heart.fill" : "heart")
                                }
                                .buttonStyle(.bordered)
                                .disabled(detail.post.isLiked || isSubmitting)
                                .tint(actionTint(for: "like"))

                                if detail.post.canGuess {
                                    TextField(LocalizedStringKey("express.detail.guessPlaceholder"), text: $guessName)
                                        .textFieldStyle(.roundedBorder)
                                    Button(LocalizedStringKey("express.detail.guessButton")) {
                                        Task { await guess() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSubmitting || !FormValidationSupport.hasText(guessName))
                                    .tint(actionTint(for: "guess"))
                                }
                            }
                        }
                    } header: {
                        Text(LocalizedStringKey("express.detail.bodySection"))
                    }

                    Section {
                        TextField(LocalizedStringKey("express.detail.commentPlaceholder"), text: $commentInput, axis: .vertical)
                            .lineLimit(2...4)
                        Button(isSubmitting ? LocalizedStringKey("express.detail.submitting") : LocalizedStringKey("express.detail.sendComment")) {
                            Task { await submitComment() }
                        }
                        .disabled(isSubmitting || !FormValidationSupport.hasText(commentInput))
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text(LocalizedStringKey("express.detail.interactionSection"))
                    }

                    if comments.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "bubble.left", title: localizedString("express.detail.noComments"), message: localizedString("express.detail.noCommentsMessage"))
                        }
                    } else {
                        Section {
                            ForEach(comments) { comment in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(comment.authorName)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(comment.publishTime)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                    }
                                    Text(comment.content)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.title)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text(LocalizedStringKey("express.detail.commentsSection"))
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(LocalizedStringKey("express.detail.title"))
        .task {
            await loadDetail()
        }
    }

    private func statItem(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(DSColor.title)
            Text(title)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let detailTask = viewModel.fetchDetail(postID: postID)
            async let commentsTask = viewModel.fetchComments(postID: postID)
            detail = try await detailTask
            comments = try await commentsTask
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("express.detail.loadFailed")
        }
    }

    private func submitComment() async {
        guard FormValidationSupport.hasText(commentInput) else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.submitComment(postID: postID, content: FormValidationSupport.trimmed(commentInput))
            commentInput = ""
            resultMessage = localizedString("express.detail.commentSent")
            comments = try await viewModel.fetchComments(postID: postID)
            try await refreshDetailAndNotifyParent()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("express.detail.commentFailed")
        }
    }

    private func like() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.like(postID: postID)
            try await refreshDetailAndNotifyParent()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("express.detail.likeFailed")
        }
    }

    private func guess() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let matched = try await viewModel.guess(postID: postID, name: FormValidationSupport.trimmed(guessName))
            resultMessage = matched ? localizedString("express.detail.guessCorrect") : localizedString("express.detail.guessWrong")
            try await refreshDetailAndNotifyParent()
            guessName = ""
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("express.detail.submitFailed")
        }
    }

    private func refreshDetailAndNotifyParent() async throws {
        let latestDetail = try await viewModel.fetchDetail(postID: postID)
        detail = latestDetail
        viewModel.replacePost(latestDetail.post)
        onPostChanged?(latestDetail)
    }

    private var normalizedNotificationTargetType: String? {
        RemoteMapperSupport.sanitizedText(notificationTargetType)
    }

    private var notificationContextText: String? {
        guard notificationID != nil else { return nil }
        switch normalizedNotificationTargetType {
        case "comment":
            return localizedString("express.notification.comment")
        case "like":
            return localizedString("express.notification.like")
        case "guess":
            return localizedString("express.notification.guess")
        default:
            return localizedString("express.notification.generic")
        }
    }

    private func actionTint(for type: String) -> Color {
        normalizedNotificationTargetType == type && notificationID != nil ? DSColor.primary : .accentColor
    }
}

private struct MyExpressPostsView: View {
    @ObservedObject var viewModel: ExpressViewModel

    @State private var posts: [ExpressPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("express.myPosts.loading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if posts.isEmpty {
                DSEmptyStateView(icon: "heart.slash", title: localizedString("express.myPosts.emptyTitle"), message: localizedString("express.myPosts.emptyMessage"))
            } else {
                List {
                    Section {
                        ForEach(posts) { post in
                            NavigationLink {
                                ExpressDetailView(viewModel: viewModel, postID: post.id) { detail in
                                    replaceLocalPost(detail.post)
                                }
                            } label: {
                                ExpressPostRow(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadData()
                }
            }
        }
        .navigationTitle(LocalizedStringKey("express.mine"))
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await viewModel.fetchMyPosts()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("express.myPosts.loadFailed")
        }
    }

    private func replaceLocalPost(_ post: ExpressPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }
}

private struct PublishExpressView: View {
    @StateObject private var viewModel: PublishExpressViewModel
    @ObservedObject var listViewModel: ExpressViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PublishExpressViewModel, listViewModel: ExpressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.listViewModel = listViewModel
    }

    var body: some View {
        Form {
            Section {
                TextField(LocalizedStringKey("express.publish.nickname"), text: $viewModel.nickname)
                TextField(LocalizedStringKey("express.publish.realNameOptional"), text: $viewModel.realName)
                Picker(LocalizedStringKey("express.publish.selfGender"), selection: $viewModel.selfGender) {
                    ForEach(ExpressGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
            } header: {
                Text(LocalizedStringKey("express.publish.yourInfo"))
            }

            Section {
                TextField(LocalizedStringKey("express.publish.targetName"), text: $viewModel.targetName)
                Picker(LocalizedStringKey("express.publish.targetGender"), selection: $viewModel.targetGender) {
                    ForEach(ExpressGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                TextField(LocalizedStringKey("express.publish.contentPlaceholder"), text: $viewModel.content, axis: .vertical)
                    .lineLimit(5...8)
            } header: {
                Text(LocalizedStringKey("express.publish.contentSection"))
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("express.publish.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? LocalizedStringKey("express.publish.submitting") : LocalizedStringKey("express.publish.submit")) {
                    Task {
                        let success = await viewModel.submit()
                        if success {
                            await listViewModel.refresh()
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExpressView(viewModel: ExpressViewModel(repository: MockExpressRepository()))
            .environmentObject(AppContainer.preview)
    }
}
