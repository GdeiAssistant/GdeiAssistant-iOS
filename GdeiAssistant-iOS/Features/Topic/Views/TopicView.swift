import SwiftUI
import PhotosUI
import UIKit

struct TopicView: View {
    @StateObject private var viewModel: TopicViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: TopicViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                DSLoadingView(text: "正在加载话题...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.posts.isEmpty {
                DSEmptyStateView(icon: "number", title: "暂无话题", message: "去发布第一条校园话题")
            } else {
                List(viewModel.posts) { post in
                    NavigationLink {
                        TopicDetailView(viewModel: viewModel, postID: post.id)
                    } label: {
                        TopicPostRow(post: post)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("校园话题")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MyTopicPostsView(viewModel: viewModel)
                }

                NavigationLink("发布") {
                    PublishTopicView(viewModel: container.makePublishTopicViewModel(), listViewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct TopicPostRow: View {
    let post: TopicPost

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if post.firstImageURL != nil {
                DSRemoteImageView(urlString: post.firstImageURL)
                    .frame(width: 84, height: 84)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("#\(post.topic)")
                            .font(.headline)
                            .foregroundStyle(DSColor.primary)
                        Text(post.authorName)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.title)
                    }
                    Spacer()
                    Text(post.publishedAt)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                }

                Text(post.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.title)
                    .lineLimit(3)

                HStack(spacing: 14) {
                    Label("\(post.likeCount)", systemImage: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    if post.imageCount > 0 {
                        Label("\(post.imageCount)", systemImage: "photo.on.rectangle")
                    }
                }
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
            }
        }
        .padding(.vertical, 6)
    }
}

struct TopicDetailView: View {
    @ObservedObject var viewModel: TopicViewModel
    let postID: String

    @State private var detail: TopicPostDetail?
    @State private var selectedImageIndex = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isLiking = false

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载详情...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                ScrollView {
                    VStack(spacing: 16) {
                        DSCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("#\(detail.post.topic)")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(DSColor.primary)
                                    Text(detail.post.authorName)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                Spacer()
                                Text(detail.post.publishedAt)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            HStack(spacing: 20) {
                                statItem(title: "点赞", value: detail.post.likeCount)
                                statItem(title: "图片", value: detail.imageURLs.count)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)

                            Text(detail.content)
                                .font(.body)
                                .foregroundStyle(DSColor.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !detail.imageURLs.isEmpty {
                            DSCard {
                                TabView(selection: $selectedImageIndex) {
                                    ForEach(Array(detail.imageURLs.enumerated()), id: \.offset) { index, url in
                                        VStack(spacing: 10) {
                                            DSRemoteImageView(urlString: url)
                                                .frame(height: 220)
                                            Text("第 \(index + 1) / \(detail.imageURLs.count) 张")
                                                .font(.caption)
                                                .foregroundStyle(DSColor.subtitle)
                                        }
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 260)
                            }
                        }

                        Button {
                            Task { await like() }
                        } label: {
                            Label(isLiking ? "处理中..." : (detail.post.isLiked ? "已点赞" : "点赞"), systemImage: detail.post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLiking || detail.post.isLiked)
                    }
                    .padding(16)
                }
                .background(DSColor.background)
            }
        }
        .navigationTitle("话题详情")
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
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(postID: postID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func like() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        do {
            try await viewModel.like(postID: postID)
            await loadDetail()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "点赞失败"
        }
    }
}

private struct MyTopicPostsView: View {
    @ObservedObject var viewModel: TopicViewModel

    @State private var posts: [TopicPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载我的话题...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if posts.isEmpty {
                DSEmptyStateView(icon: "square.and.pencil", title: "还没有发布话题", message: "去发布你的第一条校园话题")
            } else {
                List {
                    Section {
                        ForEach(posts) { post in
                            NavigationLink {
                                TopicDetailView(viewModel: viewModel, postID: post.id)
                            } label: {
                                TopicPostRow(post: post)
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
}

private struct PublishTopicView: View {
    @StateObject private var viewModel: PublishTopicViewModel
    @ObservedObject var listViewModel: TopicViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(viewModel: PublishTopicViewModel, listViewModel: TopicViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.listViewModel = listViewModel
    }

    var body: some View {
        Form {
            Section {
                TextField("输入话题标签", text: $viewModel.topic)
                TextField("输入话题内容", text: $viewModel.content, axis: .vertical)
                    .lineLimit(5...8)
                Text("可选上传图片，最多 9 张。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("话题内容")
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

                        if viewModel.images.count < 9 {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 9 - viewModel.images.count,
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
        .navigationTitle("发布话题")
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
            guard viewModel.images.count < 9 else { break }
            guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { continue }
            let contentType = item.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let image = UploadImageAsset(fileName: "topic-\(UUID().uuidString).\(fileExtension)", mimeType: mimeType, data: data)
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
        TopicView(viewModel: TopicViewModel(repository: MockTopicRepository()))
            .environmentObject(AppContainer.preview)
    }
}
