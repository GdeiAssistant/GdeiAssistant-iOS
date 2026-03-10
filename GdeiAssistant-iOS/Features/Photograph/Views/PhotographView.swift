import SwiftUI
import PhotosUI
import UIKit

struct PhotographView: View {
    @StateObject private var viewModel: PhotographViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: PhotographViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("分类", selection: $viewModel.selectedCategory) {
                    ForEach(PhotographCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedCategory) { _, _ in
                    Task { await viewModel.refresh() }
                }
            }

            if viewModel.isLoading && viewModel.posts.isEmpty {
                Section {
                    DSLoadingView(text: "正在加载摄影作品...")
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.posts.isEmpty {
                Section {
                    DSEmptyStateView(icon: "camera", title: "暂无作品", message: "当前分类下还没有内容，去发布第一张校园照片")
                }
            } else {
                Section {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PhotographDetailView(viewModel: viewModel, postID: post.id) { detail in
                                viewModel.replacePost(detail.post)
                            }
                        } label: {
                            PhotographPostRow(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(viewModel.selectedCategory.title)
                }
            }
        }
        .navigationTitle("拍好校园")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MyPhotographPostsView(viewModel: viewModel)
                }
                NavigationLink("发布") {
                    PublishPhotographView(viewModel: container.makePublishPhotographViewModel(), listViewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct PhotographPostRow: View {
    let post: PhotographPost

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if post.firstImageURL != nil {
                DSRemoteImageView(urlString: post.firstImageURL)
                    .frame(width: 84, height: 84)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(post.title)
                        .font(.headline)
                    Spacer()
                    Text(post.createdAt)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                }
                Text(post.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                HStack {
                    Text(post.authorName)
                    Spacer()
                    Text(post.category.title)
                    Label("\(post.photoCount)", systemImage: "photo.on.rectangle")
                    Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                }
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PhotographDetailView: View {
    @ObservedObject var viewModel: PhotographViewModel
    let postID: String
    var onPostChanged: ((PhotographPostDetail) -> Void)? = nil

    @State private var detail: PhotographPostDetail?
    @State private var comments: [PhotographCommentItem] = []
    @State private var commentInput = ""
    @State private var selectedImageIndex = 0
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var resultMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载作品详情...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if let detail {
                List {
                    Section {
                        HStack(spacing: 20) {
                            statItem("照片", value: detail.imageURLs.count)
                            statItem("评论", value: max(detail.post.commentCount, comments.count))
                            statItem("点赞", value: detail.post.likeCount)
                        }
                    }

                    Section {
                        Text(detail.post.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DSColor.title)
                        Text(detail.content)
                            .font(.body)
                            .foregroundStyle(DSColor.title)
                        Text("发布者：\(detail.post.authorName)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("分类：\(detail.post.category.title)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("发布时间：\(detail.post.createdAt)")
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                    } header: {
                        Text("作品信息")
                    }

                    if !detail.imageURLs.isEmpty {
                        Section {
                            TabView(selection: $selectedImageIndex) {
                                ForEach(Array(detail.imageURLs.enumerated()), id: \.offset) { index, url in
                                    DSRemoteImageView(urlString: url)
                                        .frame(height: 260)
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .automatic))
                            .frame(height: 280)
                        } header: {
                            Text("图片")
                        }
                    }

                    Section {
                        Button {
                            Task { await like() }
                        } label: {
                            Label(detail.post.isLiked ? "已点赞" : "点赞作品", systemImage: detail.post.isLiked ? "heart.fill" : "heart")
                        }
                        .buttonStyle(.bordered)
                        .disabled(detail.post.isLiked || isSubmitting)
                    } header: {
                        Text("互动状态")
                    }

                    Section {
                        TextField("写下你的评论", text: $commentInput, axis: .vertical)
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
                        Text("评论")
                    }

                    if comments.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "bubble.left", title: "暂无评论", message: "来做第一位评论的同学")
                        }
                    } else {
                        Section {
                            ForEach(comments) { comment in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(comment.authorName)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(comment.createdAt)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                    }
                                    Text(comment.content)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("作品详情")
        .task {
            await loadData()
        }
    }

    private func statItem(_ title: String, value: Int) -> some View {
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

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedDetail = try await viewModel.fetchDetail(postID: postID)
            detail = loadedDetail
            comments = loadedDetail.comments

            if comments.isEmpty {
                comments = try await viewModel.fetchComments(postID: postID)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
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

    private func submitComment() async {
        guard FormValidationSupport.hasText(commentInput) else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.submitComment(postID: postID, content: FormValidationSupport.trimmed(commentInput))
            commentInput = ""
            try await refreshDetailAndNotifyParent()
            resultMessage = "评论已发送"
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "评论失败"
        }
    }

    private func refreshDetailAndNotifyParent() async throws {
        let latestDetail = try await viewModel.fetchDetail(postID: postID)
        detail = latestDetail
        comments = latestDetail.comments.isEmpty ? (try await viewModel.fetchComments(postID: postID)) : latestDetail.comments
        viewModel.replacePost(latestDetail.post)
        onPostChanged?(latestDetail)
    }
}

private enum MyPhotographFilter: String, CaseIterable, Identifiable {
    case all
    case campus
    case life

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .campus:
            return PhotographCategory.campus.title
        case .life:
            return PhotographCategory.life.title
        }
    }
}

private struct MyPhotographPostsView: View {
    @ObservedObject var viewModel: PhotographViewModel

    @State private var posts: [PhotographPost] = []
    @State private var selectedFilter: MyPhotographFilter = .all
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var visiblePosts: [PhotographPost] {
        switch selectedFilter {
        case .all:
            return posts
        case .campus:
            return posts.filter { $0.category == .campus }
        case .life:
            return posts.filter { $0.category == .life }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载我的作品...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if visiblePosts.isEmpty {
                DSEmptyStateView(icon: "camera.macro", title: "还没有发布作品", message: selectedFilter == .all ? "去上传第一张校园照片" : "当前分类下还没有发布作品")
            } else {
                List {
                    Section {
                        Picker("分类筛选", selection: $selectedFilter) {
                            ForEach(MyPhotographFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        ForEach(visiblePosts) { post in
                            NavigationLink {
                                PhotographDetailView(viewModel: viewModel, postID: post.id) { detail in
                                    replaceLocalPost(detail.post)
                                }
                            } label: {
                                PhotographPostRow(post: post)
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
        .navigationTitle("我的作品")
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

    private func replaceLocalPost(_ post: PhotographPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }
}

private struct PublishPhotographView: View {
    @StateObject private var viewModel: PublishPhotographViewModel
    @ObservedObject var listViewModel: PhotographViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(viewModel: PublishPhotographViewModel, listViewModel: PhotographViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.listViewModel = listViewModel
    }

    var body: some View {
        Form {
            Section {
                TextField("标题", text: $viewModel.title)
                Picker("分类", selection: $viewModel.category) {
                    ForEach(PhotographCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                TextField("想说的话（选填）", text: $viewModel.content, axis: .vertical)
                    .lineLimit(3...5)
            } header: {
                Text("内容")
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.images) { image in
                            ZStack(alignment: .topTrailing) {
                                previewImageView(image)
                                Button {
                                    viewModel.removeImage(id: image.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, DSColor.danger)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                        if viewModel.images.count < 4 {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 4 - viewModel.images.count,
                                matching: .images
                            ) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                    Text("添加图片")
                                        .font(.caption)
                                }
                                .frame(width: 92, height: 92)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("图片")
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle("发布作品")
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
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadSelectedImages(from: newItems) }
        }
    }

    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        for item in items {
            guard viewModel.images.count < 4 else { break }
            guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { continue }
            let contentType = item.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let image = UploadImageAsset(fileName: "photograph-\(UUID().uuidString).\(fileExtension)", mimeType: mimeType, data: data)
            viewModel.addImage(image)
        }
        selectedPhotoItems = []
    }

    private func previewImageView(_ image: UploadImageAsset) -> some View {
        Group {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay { Image(systemName: "photo") }
            }
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PhotographView(viewModel: PhotographViewModel(repository: MockPhotographRepository()))
            .environmentObject(AppContainer.preview)
    }
}
