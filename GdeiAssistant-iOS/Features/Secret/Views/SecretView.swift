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
                DSLoadingView(text: "正在加载树洞内容...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.posts.isEmpty {
                DSEmptyStateView(icon: "moon.stars", title: "树洞还很安静", message: "来写下今天的心情")
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
        .navigationTitle("校园树洞")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MySecretPostsView(viewModel: viewModel)
                }

                NavigationLink("发布") {
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
                Text(post.isVoice ? "语音树洞" : "文本树洞")
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
                DSLoadingView(text: "正在加载详情...")
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

                            Text("评论")
                                .font(.headline)
                                .foregroundStyle(DSColor.title)

                            HStack(alignment: .bottom, spacing: 10) {
                                TextField("写下你的回应...", text: $commentText, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                DSButton(
                                    title: "发送",
                                    variant: .primary,
                                    isLoading: isSubmittingComment,
                                    isDisabled: commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ) {
                                    Task { await submitComment() }
                                }
                                .frame(width: 92)
                            }

                            if detail.comments.isEmpty {
                                Text("还没有评论，欢迎留下第一条回应。")
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
        .navigationTitle("匿名详情")
        .task {
            await loadDetail()
        }
    }

    @ViewBuilder
    private func themedDetailCard(_ detail: SecretPostDetail) -> some View {
        let theme = SecretThemeStyle.palette(for: detail.post.themeID)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(detail.post.isVoice ? "语音树洞" : "文本树洞")
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
                Text("发布者：\(detail.post.username)")
                Text("内容类型：\(detail.post.isVoice ? "语音树洞" : "文本树洞")")
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func submitComment() async {
        let trimmedContent = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            errorMessage = "请输入评论内容"
            return
        }
        guard trimmedContent.count <= 50 else {
            errorMessage = "评论内容不能超过 50 个字"
            return
        }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            detail = try await viewModel.submitComment(postID: postID, content: trimmedContent)
            commentText = ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "评论发送失败"
        }
    }

    private func toggleLike(_ post: SecretPost) async {
        isSubmittingLike = true
        defer { isSubmittingLike = false }

        do {
            detail = try await viewModel.setLike(postID: postID, liked: !post.isLiked)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "点赞操作失败"
        }
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
            return "来自互动消息：有人点赞了这条树洞"
        default:
            return "来自互动消息"
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
            if viewModel.myPosts.isEmpty {
                DSEmptyStateView(icon: "moon.stars", title: "暂无发布的树洞", message: "去写下第一条匿名心情")
            } else {
                List(viewModel.myPosts) { post in
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
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DSColor.background)
            }
        }
        .navigationTitle("我的树洞")
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
                Text(isPlaying ? "暂停语音" : "播放语音")
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
                Picker("模式", selection: $publishViewModel.mode) {
                    Text("文字").tag(SecretDraftMode.text)
                    Text("语音").tag(SecretDraftMode.voice)
                }
                .pickerStyle(.segmented)
            }

            Section {
                SecretThemePalette(selectedThemeID: $publishViewModel.selectedThemeID)
            } header: {
                Text("选择颜色")
            }

            if publishViewModel.mode == .text {
                Section {
                    TextField("写下你想说的话", text: $publishViewModel.content, axis: .vertical)
                        .lineLimit(5...8)
                    Toggle("24 小时后自动删除", isOn: $publishViewModel.deleteAfter24Hours)
                } header: {
                    Text("文本树洞")
                }
            } else {
                Section {
                    HStack {
                        Button(isRecording ? "结束录音" : "开始录音") {
                            Task { await toggleRecording() }
                        }
                        .buttonStyle(.borderedProminent)

                        if voiceFileURL != nil {
                            Button(player?.isPlaying == true ? "停止试听" : "试听语音") {
                                togglePreviewPlayback()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if isRecording {
                        Label("录音中 · \(formatDuration(recordingDuration))", systemImage: "waveform.circle")
                            .foregroundStyle(DSColor.primary)
                    } else if voiceFileURL != nil {
                        Label("已录制 · \(formatDuration(recordingDuration))", systemImage: "checkmark.circle")
                            .foregroundStyle(DSColor.secondary)
                    } else {
                        Text("点击开始录音，最长 60 秒。")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    }

                    Toggle("24 小时后自动删除", isOn: $publishViewModel.deleteAfter24Hours)
                } header: {
                    Text("语音树洞")
                } footer: {
                    Text("与 Web 一致，语音树洞通过 `voice` 文件上传到 `/secret/info`。当前 iOS 只接本地录音上传，不接微信 `voiceId`。")
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
        .navigationTitle("发布树洞")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if publishViewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text("发布")
                    }
                }
                .disabled(publishViewModel.submitState.isSubmitting || !canSubmit)
            }
        }
        .alert("提示", isPresented: Binding(
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
            Button("知道了") {
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
                publishViewModel.submitState = .failure("请先录制一段语音")
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
            publishViewModel.submitState = .success("树洞内容已发布")
        } catch {
            publishViewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
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
            publishViewModel.submitState = .failure("未获得麦克风权限")
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
            publishViewModel.submitState = .failure("录音启动失败")
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
            publishViewModel.submitState = .failure("语音试听失败")
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
