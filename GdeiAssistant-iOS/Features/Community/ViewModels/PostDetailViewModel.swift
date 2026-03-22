import Foundation
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var detail: CommunityPostDetail?
    @Published var comments: [CommunityComment] = []
    @Published var commentText = ""
    @Published var isLoading = false
    @Published var isSubmittingComment = false
    @Published var errorMessage: String?

    let postID: String

    private let repository: any CommunityRepository

    init(postID: String, repository: any CommunityRepository) {
        self.postID = postID
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard detail == nil else { return }
        await loadDetail()
    }

    func loadDetail() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let detailTask = repository.fetchPostDetail(postID: postID)
            async let commentsTask = repository.fetchComments(postID: postID)
            detail = try await detailTask
            comments = try await commentsTask
        } catch {
            detail = nil
            comments = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("community.vm.postDetailLoadFailed")
        }
    }

    func submitComment() async {
        let trimmedContent = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            errorMessage = localizedString("community.vm.enterComment")
            return
        }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            try await repository.submitComment(postID: postID, content: trimmedContent)
            commentText = ""
            await loadDetail()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("community.vm.commentFailed")
        }
    }

    func toggleLike() async {
        do {
            try await repository.toggleLike(postID: postID)
            detail = try await repository.fetchPostDetail(postID: postID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("community.vm.likeFailed")
        }
    }
}
