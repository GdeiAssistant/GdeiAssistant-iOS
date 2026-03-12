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
                DSLoadingView(text: "正在加载表白墙...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.posts.isEmpty {
                DSEmptyStateView(icon: "heart.text.square", title: "暂无内容", message: "去发布一条真诚的表白")
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
        .navigationTitle("表白墙")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MyExpressPostsView(viewModel: viewModel)
                }

                NavigationLink("发布") {
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
                Text(post.canGuess ? "可猜名" : "不可猜名")
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
                DSLoadingView(text: "正在加载详情...")
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
                                statItem(title: "点赞", value: detail.post.likeCount)
                                statItem(title: "评论", value: detail.post.commentCount)
                                if detail.post.canGuess {
                                    statItem(title: "猜中", value: detail.post.correctGuessCount)
                                }
                            }

                            Text(detail.content)
                                .font(.body)
                                .foregroundStyle(DSColor.title)

                            if detail.post.canGuess {
                                Text("猜名字功能会实时刷新猜测次数与猜中次数。")
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            if let realName = detail.realName, detail.post.canGuess {
                                Text("真实姓名：\(realName)")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            HStack {
                                Button {
                                    Task { await like() }
                                } label: {
                                    Label(detail.post.isLiked ? "已点赞" : "点赞", systemImage: detail.post.isLiked ? "heart.fill" : "heart")
                                }
                                .buttonStyle(.bordered)
                                .disabled(detail.post.isLiked || isSubmitting)
                                .tint(actionTint(for: "like"))

                                if detail.post.canGuess {
                                    TextField("输入你猜的名字", text: $guessName)
                                        .textFieldStyle(.roundedBorder)
                                    Button("猜一猜") {
                                        Task { await guess() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSubmitting || !FormValidationSupport.hasText(guessName))
                                    .tint(actionTint(for: "guess"))
                                }
                            }
                        }
                    } header: {
                        Text("正文")
                    }

                    Section {
                        TextField("写下你的留言", text: $commentInput, axis: .vertical)
                            .lineLimit(2...4)
                        Button(isSubmitting ? "提交中..." : "发送评论") {
                            Task { await submitComment() }
                        }
                        .disabled(isSubmitting || !FormValidationSupport.hasText(commentInput))
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text("互动")
                    }

                    if comments.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "bubble.left", title: "暂无评论", message: "说点什么，给这条表白一点回应")
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
                            Text("评论")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("详情")
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func submitComment() async {
        guard FormValidationSupport.hasText(commentInput) else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.submitComment(postID: postID, content: FormValidationSupport.trimmed(commentInput))
            commentInput = ""
            resultMessage = "评论已发送"
            comments = try await viewModel.fetchComments(postID: postID)
            try await refreshDetailAndNotifyParent()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "评论发送失败"
        }
    }

    private func like() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.like(postID: postID)
            try await refreshDetailAndNotifyParent()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "点赞失败"
        }
    }

    private func guess() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let matched = try await viewModel.guess(postID: postID, name: FormValidationSupport.trimmed(guessName))
            resultMessage = matched ? "你猜对了" : "猜错了，再试试"
            try await refreshDetailAndNotifyParent()
            guessName = ""
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "提交失败"
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
            return "来自互动消息：有新评论，打开详情即可查看"
        case "like":
            return "来自互动消息：有人点赞了这条表白"
        case "guess":
            return "来自互动消息：有人参与了猜名字"
        default:
            return "来自互动消息"
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
                DSLoadingView(text: "正在加载我的内容...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if posts.isEmpty {
                DSEmptyStateView(icon: "heart.slash", title: "还没有发布内容", message: "去写下一条想说的话")
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
        .navigationTitle("我的")
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载失败"
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
                TextField("昵称", text: $viewModel.nickname)
                TextField("真实姓名（选填）", text: $viewModel.realName)
                Picker("你的性别", selection: $viewModel.selfGender) {
                    ForEach(ExpressGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
            } header: {
                Text("你的信息")
            }

            Section {
                TextField("TA 的名字", text: $viewModel.targetName)
                Picker("TA 的性别", selection: $viewModel.targetGender) {
                    ForEach(ExpressGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                TextField("表白内容", text: $viewModel.content, axis: .vertical)
                    .lineLimit(5...8)
            } header: {
                Text("内容")
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle("发布表白")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? "提交中..." : "提交") {
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
