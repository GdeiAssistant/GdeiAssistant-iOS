import Foundation
import Combine

@MainActor
final class TopicViewModel: ObservableObject {
    @Published var posts: [TopicPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any TopicRepository
    private let pageSize = 20

    init(repository: any TopicRepository) {
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
            posts = try await repository.fetchPosts(start: 0, size: pageSize)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "话题列表加载失败"
        }
    }

    func fetchMyPosts() async throws -> [TopicPost] {
        try await repository.fetchMyPosts(start: 0, size: 50)
    }

    func fetchDetail(postID: String) async throws -> TopicPostDetail {
        try await repository.fetchDetail(postID: postID)
    }

    func like(postID: String) async throws {
        try await repository.like(postID: postID)
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let post = posts[index]
            posts[index] = TopicPost(
                id: post.id,
                topic: post.topic,
                contentPreview: post.contentPreview,
                authorName: post.authorName,
                publishedAt: post.publishedAt,
                likeCount: post.likeCount + (post.isLiked ? 0 : 1),
                imageCount: post.imageCount,
                firstImageURL: post.firstImageURL,
                isLiked: true
            )
        }
    }
}

@MainActor
final class PublishTopicViewModel: ObservableObject {
    @Published var topic = ""
    @Published var content = ""
    @Published var images: [UploadImageAsset] = []
    @Published var submitState: SubmitState = .idle

    private let repository: any TopicRepository

    init(repository: any TopicRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(topic) && FormValidationSupport.hasText(content) && content.count <= 250 && images.count <= 9
    }

    func addImage(_ image: UploadImageAsset) {
        guard images.count < 9 else {
            submitState = .failure("最多只能上传 9 张图片")
            return
        }
        images.append(image)
    }

    func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    func submit() async -> Bool {
        let trimmedTopic = FormValidationSupport.trimmed(topic)
        let trimmedContent = FormValidationSupport.trimmed(content)

        if let message = FormValidationSupport.requireText(trimmedTopic, message: "请输入话题标签") {
            submitState = .failure(message)
            return false
        }
        if trimmedTopic.count > 15 {
            submitState = .failure("话题标签不能超过 15 个字")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedContent, message: "请输入话题内容") {
            submitState = .failure(message)
            return false
        }
        if trimmedContent.count > 250 {
            submitState = .failure("话题内容不能超过 250 个字")
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: TopicDraft(topic: trimmedTopic, content: trimmedContent, images: images)
            )
            submitState = .success("话题已发布")
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
            return false
        }
    }
}
