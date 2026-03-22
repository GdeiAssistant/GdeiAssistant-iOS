import Foundation
import Combine

@MainActor
final class TopicViewModel: ObservableObject {
    @Published var posts: [TopicPost] = []
    @Published var searchQuery = ""
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
            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                posts = try await repository.searchPosts(keyword: trimmed, start: 0, size: pageSize)
            } else {
                posts = try await repository.fetchPosts(start: 0, size: pageSize)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("topic.vm.loadFailed")
        }
    }

    func search() async {
        await refresh()
    }

    func clearSearch() async {
        searchQuery = ""
        await refresh()
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
            submitState = .failure(localizedString("topic.vm.maxImages"))
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

        if let message = FormValidationSupport.requireText(trimmedTopic, message: localizedString("topic.vm.enterTag")) {
            submitState = .failure(message)
            return false
        }
        if trimmedTopic.count > 15 {
            submitState = .failure(localizedString("topic.vm.tagTooLong"))
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedContent, message: localizedString("topic.vm.enterContent")) {
            submitState = .failure(message)
            return false
        }
        if trimmedContent.count > 250 {
            submitState = .failure(localizedString("topic.vm.contentTooLong"))
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: TopicDraft(topic: trimmedTopic, content: trimmedContent, images: images)
            )
            submitState = .success(localizedString("topic.vm.publishSuccess"))
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("topic.vm.publishFailed"))
            return false
        }
    }
}
