import SwiftUI
import AVFoundation

struct SecretView: View {
    @StateObject private var viewModel: SecretViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var selectedTarget: SecretNavigationTarget?

    init(viewModel: SecretViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                DSLoadingView(text: localizedString("secret.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.posts.isEmpty {
                DSEmptyStateView(icon: "moon.stars", title: localizedString("secret.emptyTitle"), message: localizedString("secret.emptyMessage"))
            } else {
                List {
                    Section {
                        ForEach(viewModel.posts) { post in
                            Button {
                                selectedTarget = SecretNavigationTarget(id: post.id)
                            } label: {
                                SecretPostCard(post: post)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DSColor.background)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle(localizedString("secret.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(localizedString("secret.mine")) {
                    MySecretPostsView(viewModel: viewModel)
                }

                NavigationLink(localizedString("secret.publish")) {
                    PublishSecretView(
                        listViewModel: viewModel,
                        publishViewModel: container.makePublishSecretViewModel()
                    )
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .navigationDestination(item: $selectedTarget) { target in
            SecretDetailView(viewModel: viewModel, postID: target.id)
        }
    }
}

private struct SecretPostCard: View {
    let post: SecretPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(post.isVoice ? localizedString("secret.voiceTitle") : localizedString("secret.textTitle"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textColor.opacity(0.85))
                Spacer()
                if let timerText = post.timerText {
                    Text(timerText)
                        .font(.caption2)
                        .foregroundStyle(theme.textColor.opacity(0.75))
                }
            }

            if post.isVoice {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.headline)
                        Text(post.summary)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(theme.textColor)
            } else {
                Text(post.summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.textColor)
                    .lineLimit(3)
            }

            HStack(spacing: 12) {
                Text(post.createdAt)
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                Label("\(post.commentCount)", systemImage: "bubble.left")
            }
            .font(.caption)
            .foregroundStyle(theme.textColor.opacity(0.82))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var theme: SecretThemeStyle.Palette {
        SecretThemeStyle.palette(for: post.themeID)
    }
}

struct SecretDetailView: View {
    @ObservedObject var viewModel: SecretViewModel
    let postID: String
    let notificationTargetType: String?
    let notificationTargetSubID: String?
    let notificationID: String?

    @State private var detail: SecretPostDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var commentText = ""
    @State private var isSubmittingComment = false
    @State private var isSubmittingLike = false

    init(
        viewModel: SecretViewModel,
        postID: String,
        notificationTargetType: String? = nil,
        notificationTargetSubID: String? = nil,
        notificationID: String? = nil
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.postID = postID
        self.notificationTargetType = notificationTargetType
        self.notificationTargetSubID = notificationTargetSubID
        self.notificationID = notificationID
    }

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("secret.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                ScrollView {
                    VStack(spacing: 14) {
                        themedDetailCard(detail)

                        DSCard {
                            if let notificationContextText {
                                Text(notificationContextText)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.primary)
                            }

                            Text(localizedString("secret.comment"))
                                .font(.headline)
                                .foregroundStyle(DSColor.title)

                            HStack(alignment: .bottom, spacing: 10) {
                                TextField(localizedString("secret.commentPlaceholder"), text: $commentText, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                DSButton(
                                    title: localizedString("secret.send"),
                                    variant: .primary,
                                    isLoading: isSubmittingComment,
                                    isDisabled: commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ) {
                                    Task { await submitComment() }
                                }
                                .frame(width: 92)
                            }

                            if detail.comments.isEmpty {
                                Text(localizedString("secret.emptyComments"))
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                            } else {
                                ForEach(detail.comments) { comment in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(comment.authorName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(DSColor.title)
                                            Spacer()
                                            Text(comment.createdAt)
                                                .font(.caption)
                                                .foregroundStyle(DSColor.subtitle)
                                        }
                                        Text(comment.content)
                                            .font(.subheadline)
                                            .foregroundStyle(DSColor.title)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(DSColor.background)
                }
            }
        }
        .navigationTitle(localizedString("secret.anonymousDetail"))
        .task {
            await loadDetail()
        }
    }

    @ViewBuilder
    private func themedDetailCard(_ detail: SecretPostDetail) -> some View {
        let theme = SecretThemeStyle.palette(for: detail.post.themeID)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(detail.post.isVoice ? localizedString("secret.voiceTitle") : localizedString("secret.textTitle"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textColor.opacity(0.85))
                Spacer()
                Text(detail.post.stateText)
                    .font(.caption)
                    .foregroundStyle(theme.textColor.opacity(0.75))
            }

            if detail.post.isVoice, let voiceURL = detail.post.voiceURL {
                SecretVoicePlayer(urlString: voiceURL, foregroundColor: theme.textColor)
            }

            Text(detail.content)
                .font(.body)
                .foregroundStyle(theme.textColor)
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(localizedString("secret.publisher"))\(detail.post.username)")
                Text("\(localizedString("secret.contentType"))\(detail.post.isVoice ? localizedString("secret.voiceTitle") : localizedString("secret.textTitle"))")
                if let timerText = detail.post.timerText {
                    Text(timerText)
                }
            }
            .font(.caption)
            .foregroundStyle(theme.textColor.opacity(0.8))

            HStack(spacing: 16) {
                Button {
                    Task { await toggleLike(detail.post) }
                } label: {
                    Label(
                        "\(detail.post.likeCount)",
                        systemImage: detail.post.isLiked ? "heart.fill" : "heart"
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.textColor)
                .disabled(isSubmittingLike)

                Label("\(detail.post.commentCount)", systemImage: "bubble.left")
                    .foregroundStyle(theme.textColor.opacity(0.82))
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(actionHighlightBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(postID: postID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("secret.detailLoadFailed")
        }
    }

    private func submitComment() async {
        let trimmedContent = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            errorMessage = localizedString("secret.commentEmpty")
            return
        }
        guard trimmedContent.count <= 50 else {
            errorMessage = localizedString("secret.commentTooLong")
            return
        }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            detail = try await viewModel.submitComment(postID: postID, content: trimmedContent)
            commentText = ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("secret.commentFailed")
        }
    }

    private func toggleLike(_ post: SecretPost) async {
        isSubmittingLike = true
        defer { isSubmittingLike = false }

        do {
            detail = try await viewModel.setLike(postID: postID, liked: !post.isLiked)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("secret.likeFailed")
        }
    }

    private var normalizedNotificationTargetType: String? {
        RemoteMapperSupport.sanitizedText(notificationTargetType)
    }

    private var notificationContextText: String? {
        guard notificationID != nil else { return nil }
        switch normalizedNotificationTargetType {
        case "comment":
            return localizedString("secret.fromInteractionComment")
        case "like":
            return localizedString("secret.fromInteractionLike")
        default:
            return localizedString("secret.fromInteraction")
        }
    }

    private var actionHighlightBackground: Color {
        normalizedNotificationTargetType == "like" && notificationID != nil
            ? DSColor.primary.opacity(0.12)
            : .clear
    }
}

private struct SecretNavigationTarget: Hashable, Identifiable {
    let id: String
}

private struct MySecretPostsView: View {
    @ObservedObject var viewModel: SecretViewModel
    @State private var selectedTarget: SecretNavigationTarget?

    var body: some View {
        Group {
            if viewModel.myPosts.isEmpty && !viewModel.isLoading {
                DSEmptyStateView(icon: "moon.stars", title: localizedString("secret.myEmpty"), message: localizedString("secret.myEmptyMsg"))
            } else {
                List {
                    ForEach(viewModel.myPosts) { post in
                        Button {
                            selectedTarget = SecretNavigationTarget(id: post.id)
                        } label: {
                            HStack {
                                Spacer(minLength: 0)
                                SecretPostCard(post: post)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .onAppear {
                            if post.id == viewModel.myPosts.last?.id {
                                Task { await viewModel.loadMoreMyPosts() }
                            }
                        }
                    }

                    if viewModel.isLoadingMoreMyPosts {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text(localizedString("secret.loadingMore"))
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else if !viewModel.hasMoreMyPosts && !viewModel.myPosts.isEmpty {
                        HStack {
                            Spacer()
                            Text(localizedString("secret.noMore"))
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DSColor.background)
            }
        }
        .navigationTitle(localizedString("secret.myTitle"))
        .refreshable {
            await viewModel.refresh()
        }
        .navigationDestination(item: $selectedTarget) { target in
            SecretDetailView(viewModel: viewModel, postID: target.id)
        }
    }
}

private struct SecretVoicePlayer: View {
    let urlString: String
    let foregroundColor: Color

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        Button {
            toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                Text(isPlaying ? localizedString("secret.pauseVoice") : localizedString("secret.playVoice"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "waveform")
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(foregroundColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .onDisappear {
            player?.pause()
            player = nil
            isPlaying = false
        }
    }

    private func toggle() {
        guard let url = URL(string: urlString) else { return }
        if player == nil {
            player = AVPlayer(url: url)
        }
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

struct PublishSecretView: View {
    @ObservedObject var listViewModel: SecretViewModel
    @StateObject private var publishViewModel: PublishSecretViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var voiceFileURL: URL?
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordTimer: Timer?

    init(
        listViewModel: SecretViewModel,
        publishViewModel: PublishSecretViewModel
    ) {
        self.listViewModel = listViewModel
        _publishViewModel = StateObject(wrappedValue: publishViewModel)
    }

    var body: some View {
        Form {
            Section {
                Picker(localizedString("secret.modeLabel"), selection: $publishViewModel.mode) {
                    Text(localizedString("secret.modeText")).tag(SecretDraftMode.text)
                    Text(localizedString("secret.modeVoice")).tag(SecretDraftMode.voice)
                }
                .pickerStyle(.segmented)
            }

            Section {
                SecretThemePalette(selectedThemeID: $publishViewModel.selectedThemeID)
            } header: {
                Text(localizedString("secret.colorPicker"))
            }

            if publishViewModel.mode == .text {
                Section {
                    TextField(localizedString("secret.textPlaceholder"), text: $publishViewModel.content, axis: .vertical)
                        .lineLimit(5...8)
                    Toggle(localizedString("secret.autoDelete"), isOn: $publishViewModel.deleteAfter24Hours)
                } header: {
                    Text(localizedString("secret.textTitle"))
                }
            } else {
                Section {
                    HStack {
                        Button(isRecording ? localizedString("secret.stopRecording") : localizedString("secret.startRecording")) {
                            Task { await toggleRecording() }
                        }
                        .buttonStyle(.borderedProminent)

                        if voiceFileURL != nil {
                            Button(player?.isPlaying == true ? localizedString("secret.stopPreview") : localizedString("secret.previewVoice")) {
                                togglePreviewPlayback()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if isRecording {
                        Label("\(localizedString("secret.recording")) · \(formatDuration(recordingDuration))", systemImage: "waveform.circle")
                            .foregroundStyle(DSColor.primary)
                    } else if voiceFileURL != nil {
                        Label("\(localizedString("secret.recorded")) · \(formatDuration(recordingDuration))", systemImage: "checkmark.circle")
                            .foregroundStyle(DSColor.secondary)
                    } else {
                        Text(localizedString("secret.recordingHint"))
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    }

                    Toggle(localizedString("secret.autoDelete"), isOn: $publishViewModel.deleteAfter24Hours)
                } header: {
                    Text(localizedString("secret.voiceTitle"))
                } footer: {
                    Text(localizedString("secret.voiceNote"))
                }
            }

            if let failureMessage = publishViewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .navigationTitle(localizedString("secret.publishTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if publishViewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text(localizedString("secret.publish"))
                    }
                }
                .disabled(publishViewModel.submitState.isSubmitting || !canSubmit)
            }
        }
        .alert(localizedString("secret.notice"), isPresented: Binding(
            get: {
                if case .success = publishViewModel.submitState { return true }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    publishViewModel.submitState = .idle
                }
            }
        )) {
            Button(localizedString("secret.understood")) {
                publishViewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(publishViewModel.submitState.message ?? "")
        }
        .onDisappear {
            stopRecording(resetRecorder: true)
            player?.stop()
            player = nil
        }
    }

    private var canSubmit: Bool {
        switch publishViewModel.mode {
        case .text:
            return publishViewModel.isFormValid
        case .voice:
            return voiceFileURL != nil
        }
    }

    private func publish() async {
        let voiceDraft: SecretVoiceDraft?
        if publishViewModel.mode == .voice {
            guard let voiceFileURL,
                  let data = try? Data(contentsOf: voiceFileURL) else {
                publishViewModel.submitState = .failure(localizedString("secret.noRecording"))
                return
            }
            voiceDraft = SecretVoiceDraft(fileData: data, fileName: voiceFileURL.lastPathComponent, mimeType: "audio/m4a")
        } else {
            voiceDraft = nil
        }

        guard let draft = publishViewModel.buildDraft(voice: voiceDraft) else { return }

        publishViewModel.submitState = .submitting

        do {
            try await listViewModel.publish(draft: draft)
            publishViewModel.submitState = .success(localizedString("secret.published"))
        } catch {
            publishViewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("secret.publishFailed"))
        }
    }

    private func toggleRecording() async {
        if isRecording {
            stopRecording(resetRecorder: false)
        } else {
            await startRecording()
        }
    }

    private func startRecording() async {
        let granted = await requestMicrophonePermission()
        guard granted else {
            publishViewModel.submitState = .failure(localizedString("secret.micDenied"))
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("secret-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record(forDuration: 60)
            self.recorder = recorder
            self.voiceFileURL = url
            self.recordingDuration = 0
            self.isRecording = true
            self.player?.stop()
            self.player = nil
            self.recordTimer?.invalidate()
            self.recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                recordingDuration += 1
                if recordingDuration >= 60 {
                    stopRecording(resetRecorder: false)
                }
            }
        } catch {
            publishViewModel.submitState = .failure(localizedString("secret.recordFailed"))
        }
    }

    private func stopRecording(resetRecorder: Bool) {
        recordTimer?.invalidate()
        recordTimer = nil
        recorder?.stop()
        isRecording = false
        if resetRecorder {
            recorder = nil
        }
    }

    private func togglePreviewPlayback() {
        guard let voiceFileURL else { return }
        if let player, player.isPlaying {
            player.stop()
            self.player = nil
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: voiceFileURL)
            player.play()
            self.player = player
        } catch {
            publishViewModel.submitState = .failure(localizedString("secret.previewFailed"))
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func formatDuration(_ value: TimeInterval) -> String {
        let total = Int(value)
        let minute = String(format: "%02d", total / 60)
        let second = String(format: "%02d", total % 60)
        return "\(minute):\(second)"
    }
}

private struct SecretThemePalette: View {
    @Binding var selectedThemeID: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SecretRemoteMapper.themeIDs, id: \.self) { themeID in
                Button {
                    selectedThemeID = themeID
                } label: {
                    Circle()
                        .fill(SecretThemeStyle.palette(for: themeID).background)
                        .frame(width: 42, height: 42)
                        .overlay {
                            if selectedThemeID == themeID {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(SecretThemeStyle.palette(for: themeID).textColor)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private enum SecretThemeStyle {
    struct Palette {
        let background: Color
        let textColor: Color
    }

    static func palette(for themeID: Int) -> Palette {
        switch themeID {
        case 1:
            return Palette(background: Color(red: 0.96, green: 0.94, blue: 0.87), textColor: .black)
        case 2:
            return Palette(background: Color(red: 0.84, green: 0.52, blue: 0.56), textColor: .white)
        case 3:
            return Palette(background: Color(red: 0.56, green: 0.68, blue: 0.79), textColor: .white)
        case 4:
            return Palette(background: Color(red: 0.91, green: 0.67, blue: 0.49), textColor: .white)
        case 5:
            return Palette(background: Color(red: 0.54, green: 0.74, blue: 0.63), textColor: .white)
        case 6:
            return Palette(background: Color(red: 0.64, green: 0.54, blue: 0.77), textColor: .white)
        case 7:
            return Palette(background: Color(red: 0.37, green: 0.63, blue: 0.73), textColor: .white)
        case 8:
            return Palette(background: Color(red: 0.93, green: 0.52, blue: 0.44), textColor: .white)
        case 9:
            return Palette(background: Color(red: 0.95, green: 0.73, blue: 0.39), textColor: .white)
        case 10:
            return Palette(background: Color(red: 0.40, green: 0.49, blue: 0.68), textColor: .white)
        case 11:
            return Palette(background: Color(red: 0.33, green: 0.56, blue: 0.53), textColor: .white)
        case 12:
            return Palette(background: Color(red: 0.58, green: 0.43, blue: 0.32), textColor: .white)
        default:
            return Palette(background: DSColor.cardBackground, textColor: DSColor.title)
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        SecretView(viewModel: SecretViewModel(repository: MockSecretRepository()))
            .environmentObject(container)
    }
}
