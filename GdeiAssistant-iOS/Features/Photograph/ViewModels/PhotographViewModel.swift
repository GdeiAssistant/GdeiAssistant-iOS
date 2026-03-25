import Foundation
import Combine

@MainActor
final class PhotographViewModel: ObservableObject {
    @Published var selectedCategory: PhotographCategory = .campus
    @Published var posts: [PhotographPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any PhotographRepository
    private let pageSize = 20

    init(repository: any PhotographRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard posts.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await repository.fetchPosts(category: selectedCategory, start: 0, size: pageSize)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("photograph.loadFailed")
        }
    }

    func fetchMyPosts() async throws -> [PhotographPost] {
        try await repository.fetchMyPosts(start: 0, size: 50)
    }

    func fetchDetail(postID: String) async throws -> PhotographPostDetail {
        try await repository.fetchDetail(postID: postID)
    }

    func fetchComments(postID: String) async throws -> [PhotographCommentItem] {
        try await repository.fetchComments(postID: postID)
    }

    func like(postID: String) async throws {
        try await repository.like(postID: postID)
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let post = posts[index]
            posts[index] = PhotographPost(
                id: post.id,
                title: post.title,
                contentPreview: post.contentPreview,
                authorName: post.authorName,
                createdAt: post.createdAt,
                likeCount: post.likeCount + (post.isLiked ? 0 : 1),
                commentCount: post.commentCount,
                photoCount: post.photoCount,
                firstImageURL: post.firstImageURL,
                isLiked: true,
                category: post.category
            )
        }
    }

    func submitComment(postID: String, content: String) async throws {
        try await repository.submitComment(postID: postID, content: content)
        updatePost(postID: postID) { post in
            PhotographPost(
                id: post.id,
                title: post.title,
                contentPreview: post.contentPreview,
                authorName: post.authorName,
                createdAt: post.createdAt,
                likeCount: post.likeCount,
                commentCount: post.commentCount + 1,
                photoCount: post.photoCount,
                firstImageURL: post.firstImageURL,
                isLiked: post.isLiked,
                category: post.category
            )
        }
    }

    func replacePost(_ post: PhotographPost) {
        updatePost(postID: post.id) { _ in post }
    }

    private func updatePost(postID: String, transform: (PhotographPost) -> PhotographPost) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index] = transform(posts[index])
    }
}

@MainActor
final class PublishPhotographViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var category: PhotographCategory = .life
    @Published var images: [UploadImageAsset] = []
    @Published var submitState: SubmitState = .idle

    private let repository: any PhotographRepository

    init(repository: any PhotographRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(title) && !images.isEmpty && images.count <= 4
    }

    func addImage(_ image: UploadImageAsset) {
        guard images.count < 4 else {
            submitState = .failure(localizedString("photograph.maxImages"))
            return
        }
        images.append(image)
    }

    func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    func submit() async -> Bool {
        let trimmedTitle = FormValidationSupport.trimmed(title)
        let trimmedContent = FormValidationSupport.trimmed(content)

        if let message = FormValidationSupport.requireText(trimmedTitle, message: localizedString("photograph.titleEmpty")) {
            submitState = .failure(message)
            return false
        }
        if trimmedTitle.count > 25 {
            submitState = .failure(localizedString("photograph.titleTooLong"))
            return false
        }
        if trimmedContent.count > 150 {
            submitState = .failure(localizedString("photograph.contentTooLong"))
            return false
        }
        if images.isEmpty {
            submitState = .failure(localizedString("photograph.noImage"))
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: PhotographDraft(title: trimmedTitle, content: trimmedContent, category: category, images: images)
            )
            submitState = .success(localizedString("photograph.publishSuccess"))
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("photograph.publishFailed"))
            return false
        }
    }
}
