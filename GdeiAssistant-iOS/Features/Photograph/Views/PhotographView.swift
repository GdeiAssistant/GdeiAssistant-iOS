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
                Picker(localizedString("photograph.category"), selection: $viewModel.selectedCategory) {
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
                    DSLoadingView(text: localizedString("photograph.loading"))
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.posts.isEmpty {
                Section {
                    DSEmptyStateView(
                        icon: "camera",
                        title: localizedString("photograph.noWorks"),
                        message: localizedString("photograph.emptyCategoryMessage")
                    )
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
        .navigationTitle(localizedString("photograph.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(localizedString("photograph.mine")) {
                    MyPhotographPostsView(viewModel: viewModel)
                }
                NavigationLink(localizedString("photograph.publish")) {
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
    let notificationTargetType: String?
    let notificationTargetSubID: String?
    let notificationID: String?
    var onPostChanged: ((PhotographPostDetail) -> Void)? = nil

    @State private var detail: PhotographPostDetail?
    @State private var comments: [PhotographCommentItem] = []
    @State private var commentInput = ""
    @State private var selectedImageIndex = 0
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var resultMessage: String?

    init(
        viewModel: PhotographViewModel,
        postID: String,
        notificationTargetType: String? = nil,
        notificationTargetSubID: String? = nil,
        notificationID: String? = nil,
        onPostChanged: ((PhotographPostDetail) -> Void)? = nil
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
                DSLoadingView(text: localizedString("photograph.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if let detail {
                List {
                    Section {
                        if let notificationContextText {
                            Text(notificationContextText)
                                .font(.caption)
                                .foregroundStyle(DSColor.primary)
                        }

                        HStack(spacing: 20) {
                            statItem(localizedString("photograph.photoSection"), value: detail.imageURLs.count)
                            statItem(localizedString("photograph.comment"), value: max(detail.post.commentCount, comments.count))
                            statItem(localizedString("photograph.like"), value: detail.post.likeCount)
                        }
                    }

                    Section {
                        Text(detail.post.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DSColor.title)
                        Text(detail.content)
                            .font(.body)
                            .foregroundStyle(DSColor.title)
                        Text("\(localizedString("photograph.publisher"))\(detail.post.authorName)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("\(localizedString("photograph.categoryLabel"))\(detail.post.category.title)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("\(localizedString("photograph.publishedAt"))\(detail.post.createdAt)")
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                    } header: {
                        Text(localizedString("photograph.infoSection"))
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
                            Text(localizedString("photograph.imageSection"))
                        }
                    }

                    Section {
                        Button {
                            Task { await like() }
                        } label: {
                            Label(detail.post.isLiked ? localizedString("photograph.liked") : localizedString("photograph.likeItem"), systemImage: detail.post.isLiked ? "heart.fill" : "heart")
                        }
                        .buttonStyle(.bordered)
                        .disabled(detail.post.isLiked || isSubmitting)
                        .tint(isLikeNotification ? DSColor.primary : .accentColor)
                    } header: {
                        Text(localizedString("photograph.interactionStatus"))
                    }

                    Section {
                        TextField(localizedString("photograph.commentPlaceholder"), text: $commentInput, axis: .vertical)
                            .lineLimit(2...4)
                        Button(isSubmitting ? localizedString("photograph.submitting") : localizedString("photograph.sendComment")) {
                            Task { await submitComment() }
                        }
                        .disabled(isSubmitting || !FormValidationSupport.hasText(commentInput))
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text(localizedString("photograph.comment"))
                    }

                    if comments.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "bubble.left", title: localizedString("photograph.noComments"), message: localizedString("photograph.beFirstComment"))
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
        .navigationTitle(localizedString("photograph.detailTitle"))
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("photograph.detailLoadFailed")
        }
    }

    private func like() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.like(postID: postID)
            try await refreshDetailAndNotifyParent()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("photograph.likeFailed")
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
            resultMessage = localizedString("photograph.commentSent")
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("photograph.commentFailed")
        }
    }

    private func refreshDetailAndNotifyParent() async throws {
        let latestDetail = try await viewModel.fetchDetail(postID: postID)
        detail = latestDetail
        comments = latestDetail.comments.isEmpty ? (try await viewModel.fetchComments(postID: postID)) : latestDetail.comments
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
            return localizedString("photograph.fromInteractionComment")
        case "like":
            return localizedString("photograph.fromInteractionLike")
        default:
            return localizedString("photograph.fromInteraction")
        }
    }

    private var isLikeNotification: Bool {
        normalizedNotificationTargetType == "like" && notificationID != nil
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
            return localizedString("photograph.all")
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
                DSLoadingView(text: localizedString("photograph.myLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if visiblePosts.isEmpty {
                DSEmptyStateView(
                    icon: "camera.macro",
                    title: localizedString("photograph.myEmpty"),
                    message: selectedFilter == .all
                        ? localizedString("photograph.myEmptyMsg")
                        : localizedString("photograph.myEmptyFilteredMessage")
                )
            } else {
                List {
                    Section {
                        Picker(localizedString("photograph.filterCategory"), selection: $selectedFilter) {
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
        .navigationTitle(localizedString("photograph.myTitle"))
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("photograph.loadFailed")
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
                TextField(localizedString("photograph.titleField"), text: $viewModel.title)
                Picker(localizedString("photograph.category"), selection: $viewModel.category) {
                    ForEach(PhotographCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                TextField(localizedString("photograph.descriptionField"), text: $viewModel.content, axis: .vertical)
                    .lineLimit(3...5)
            } header: {
                Text(localizedString("photograph.content"))
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
                                    Text(localizedString("photograph.addImage"))
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
                Text(localizedString("photograph.imageSection"))
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle(localizedString("photograph.publishTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? localizedString("photograph.submitting") : localizedString("common.submit")) {
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
