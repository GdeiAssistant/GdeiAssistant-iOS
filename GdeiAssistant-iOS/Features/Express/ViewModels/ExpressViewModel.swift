import Foundation
import Combine

@MainActor
final class ExpressViewModel: ObservableObject {
    @Published var posts: [ExpressPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any ExpressRepository
    private let pageSize = 20

    init(repository: any ExpressRepository) {
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "表白墙加载失败"
        }
    }

    func fetchMyPosts() async throws -> [ExpressPost] {
        try await repository.fetchMyPosts(start: 0, size: 50)
    }

    func fetchDetail(postID: String) async throws -> ExpressPostDetail {
        try await repository.fetchDetail(postID: postID)
    }

    func fetchComments(postID: String) async throws -> [ExpressCommentItem] {
        try await repository.fetchComments(postID: postID)
    }

    func submitComment(postID: String, content: String) async throws {
        try await repository.submitComment(postID: postID, content: content)
        updatePost(postID: postID) { post in
            ExpressPost(
                id: post.id,
                nickname: post.nickname,
                targetName: post.targetName,
                contentPreview: post.contentPreview,
                publishTime: post.publishTime,
                likeCount: post.likeCount,
                commentCount: post.commentCount + 1,
                guessCount: post.guessCount,
                correctGuessCount: post.correctGuessCount,
                isLiked: post.isLiked,
                canGuess: post.canGuess,
                selfGender: post.selfGender,
                targetGender: post.targetGender
            )
        }
    }

    func like(postID: String) async throws {
        try await repository.like(postID: postID)
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            let post = posts[index]
            posts[index] = ExpressPost(
                id: post.id,
                nickname: post.nickname,
                targetName: post.targetName,
                contentPreview: post.contentPreview,
                publishTime: post.publishTime,
                likeCount: post.likeCount + (post.isLiked ? 0 : 1),
                commentCount: post.commentCount,
                guessCount: post.guessCount,
                correctGuessCount: post.correctGuessCount,
                isLiked: true,
                canGuess: post.canGuess,
                selfGender: post.selfGender,
                targetGender: post.targetGender
            )
        }
    }

    func guess(postID: String, name: String) async throws -> Bool {
        let matched = try await repository.guess(postID: postID, name: name)
        updatePost(postID: postID) { post in
            ExpressPost(
                id: post.id,
                nickname: post.nickname,
                targetName: post.targetName,
                contentPreview: post.contentPreview,
                publishTime: post.publishTime,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                guessCount: post.guessCount + 1,
                correctGuessCount: post.correctGuessCount + (matched ? 1 : 0),
                isLiked: post.isLiked,
                canGuess: post.canGuess,
                selfGender: post.selfGender,
                targetGender: post.targetGender
            )
        }
        return matched
    }

    func replacePost(_ post: ExpressPost) {
        updatePost(postID: post.id) { _ in post }
    }

    private func updatePost(postID: String, transform: (ExpressPost) -> ExpressPost) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index] = transform(posts[index])
    }
}

@MainActor
final class PublishExpressViewModel: ObservableObject {
    @Published var nickname = ""
    @Published var realName = ""
    @Published var selfGender: ExpressGender = .secret
    @Published var targetName = ""
    @Published var targetGender: ExpressGender = .secret
    @Published var content = ""
    @Published var submitState: SubmitState = .idle

    private let repository: any ExpressRepository

    init(repository: any ExpressRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(nickname) &&
        FormValidationSupport.hasText(targetName) &&
        FormValidationSupport.hasText(content)
    }

    func submit() async -> Bool {
        let trimmedNickname = FormValidationSupport.trimmed(nickname)
        let trimmedRealName = FormValidationSupport.trimmed(realName)
        let trimmedTargetName = FormValidationSupport.trimmed(targetName)
        let trimmedContent = FormValidationSupport.trimmed(content)

        if let message = FormValidationSupport.requireText(trimmedNickname, message: "请输入昵称") {
            submitState = .failure(message)
            return false
        }
        if trimmedNickname.count > 10 {
            submitState = .failure("昵称不能超过 10 个字")
            return false
        }
        if trimmedRealName.count > 10 {
            submitState = .failure("真名不能超过 10 个字")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedTargetName, message: "请输入 TA 的名字") {
            submitState = .failure(message)
            return false
        }
        if trimmedTargetName.count > 10 {
            submitState = .failure("TA 的名字不能超过 10 个字")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedContent, message: "请填写表白内容") {
            submitState = .failure(message)
            return false
        }
        if trimmedContent.count > 250 {
            submitState = .failure("表白内容不能超过 250 个字")
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: ExpressDraft(
                    nickname: trimmedNickname,
                    realName: trimmedRealName.isEmpty ? nil : trimmedRealName,
                    selfGender: selfGender,
                    targetName: trimmedTargetName,
                    content: trimmedContent,
                    targetGender: targetGender
                )
            )
            submitState = .success("表白已发布")
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
            return false
        }
    }
}
