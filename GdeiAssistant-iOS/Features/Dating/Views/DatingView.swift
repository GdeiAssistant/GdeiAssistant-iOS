import SwiftUI
import PhotosUI
import UIKit

struct DatingView: View {
    @StateObject private var viewModel: DatingHallViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: DatingHallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("展示分区", selection: areaBinding) {
                    ForEach(DatingArea.allCases) { area in
                        Text(area.title).tag(area)
                    }
                }
                .pickerStyle(.segmented)
            }

            if viewModel.isLoading && viewModel.profiles.isEmpty {
                Section {
                    DSLoadingView(text: "正在加载卖室友资料...")
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.profiles.isEmpty {
                Section {
                    DSEmptyStateView(icon: "person.3", title: "暂无资料", message: "当前分区还没有新的卖室友资料")
                }
            } else {
                Section {
                    ForEach(viewModel.profiles) { profile in
                        NavigationLink {
                            DatingDetailView(viewModel: viewModel, profileID: profile.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                DSRemoteImageView(urlString: profile.imageURL, fallbackSystemImage: "person.crop.rectangle")
                                    .frame(width: 96, height: 120)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(profile.nickname)
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)

                                    Text(profile.headline)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)

                                    Text("来自\(profile.hometown)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)

                                    Text(profile.bio)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.title)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle("卖室友")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("互动中心") {
                    DatingCenterView(viewModel: container.makeDatingCenterViewModel())
                }

                NavigationLink("发布") {
                    PublishDatingView(
                        listViewModel: viewModel,
                        viewModel: container.makePublishDatingViewModel()
                    )
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var areaBinding: Binding<DatingArea> {
        Binding(
            get: { viewModel.selectedArea },
            set: { newValue in
                Task { await viewModel.updateArea(newValue) }
            }
        )
    }
}

struct DatingCenterView: View {
    @StateObject private var viewModel: DatingCenterViewModel

    init(viewModel: DatingCenterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        DatingCenterContent(viewModel: viewModel, navigationTitle: "互动中心")
    }
}

private struct DatingCenterContent: View {
    @ObservedObject var viewModel: DatingCenterViewModel
    let navigationTitle: String

    @State private var confirmHideID: String?

    var body: some View {
        List {
            Section {
                Picker("互动中心", selection: $viewModel.selectedTab) {
                    ForEach(DatingCenterTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedTab) { _, _ in
                    Task { await viewModel.loadData() }
                }
            }

            if let actionMessage = viewModel.actionMessage {
                Section {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.primary)
                }
            }

            contentSection
        }
        .navigationTitle(navigationTitle)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .confirmationDialog(
            "确定要隐藏这条发布吗？隐藏后他人将无法在大厅看到。",
            isPresented: Binding(
                get: { confirmHideID != nil },
                set: { if !$0 { confirmHideID = nil } }
            )
        ) {
            Button("确认隐藏", role: .destructive) {
                guard let confirmHideID else { return }
                Task { await viewModel.hideProfile(id: confirmHideID) }
            }
            Button("取消", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.selectedTab {
        case .received:
            if viewModel.isLoading && viewModel.receivedItems.isEmpty {
                Section { DSLoadingView(text: "正在加载...") }
            } else if viewModel.receivedItems.isEmpty {
                Section { DSEmptyStateView(icon: "tray", title: "暂无收到的请求", message: "有人给你留言时会显示在这里") }
            } else {
                Section {
                    ForEach(viewModel.receivedItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 10) {
                                    DSAvatarView(urlString: item.avatarURL, size: 40)
                                    Text(item.senderName)
                                        .font(.headline)
                                }
                                Spacer()
                                Text(item.time)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            Text(item.content)
                                .font(.subheadline)
                            if item.status == .pending {
                                HStack {
                                    Button("同意") {
                                        Task { await viewModel.updatePickState(id: item.id, state: .accepted) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button("拒绝") {
                                        Task { await viewModel.updatePickState(id: item.id, state: .rejected) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                Text(item.status.title)
                                    .font(.caption)
                                    .foregroundStyle(item.status == .accepted ? DSColor.primary : DSColor.danger)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("收到的撩")
                }
            }
        case .sent:
            if viewModel.isLoading && viewModel.sentItems.isEmpty {
                Section { DSLoadingView(text: "正在加载...") }
            } else if viewModel.sentItems.isEmpty {
                Section { DSEmptyStateView(icon: "paperplane", title: "暂无发出的请求", message: "有人回应后会显示在这里") }
            } else {
                Section {
                    ForEach(viewModel.sentItems) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 10) {
                                    DSAvatarView(urlString: item.targetAvatarURL, size: 40)
                                    Text(item.targetName)
                                        .font(.headline)
                                }
                                Spacer()
                                Text(item.status.title)
                                    .font(.caption)
                                    .foregroundStyle(item.status == .accepted ? DSColor.primary : DSColor.subtitle)
                            }
                            Text(item.content)
                                .font(.subheadline)
                            if item.status == .accepted {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let qq = item.targetQq, !qq.isEmpty {
                                        Text("QQ：\(qq)")
                                    }
                                    if let wechat = item.targetWechat, !wechat.isEmpty {
                                        Text("微信：\(wechat)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("我发出的")
                }
            }
        case .posts:
            if viewModel.isLoading && viewModel.myPosts.isEmpty {
                Section { DSLoadingView(text: "正在加载...") }
            } else if viewModel.myPosts.isEmpty {
                Section { DSEmptyStateView(icon: "person.crop.square", title: "暂无发布", message: "当前没有可处理的卖室友发布") }
            } else {
                Section {
                    ForEach(viewModel.myPosts) { item in
                        HStack {
                            HStack(spacing: 10) {
                                DSAvatarView(urlString: item.imageURL, size: 40)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("\(item.grade) · \(item.faculty) · 来自\(item.hometown)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                    Text(item.publishTime)
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            Spacer()
                            Button("隐藏", role: .destructive) {
                                confirmHideID = item.id
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("我的发布")
                }
            }
        }
    }
}

private struct DatingDetailView: View {
    @ObservedObject var viewModel: DatingHallViewModel
    let profileID: String

    @State private var detail: DatingProfileDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var pickContent = ""
    @State private var isSubmittingPick = false
    @State private var actionMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载资料详情...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                List {
                    Section {
                        HStack(alignment: .top, spacing: 16) {
                            DSRemoteImageView(urlString: detail.profile.imageURL, fallbackSystemImage: "person.crop.rectangle")
                                .frame(width: 120, height: 160)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(detail.profile.nickname)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(DSColor.title)
                                Text(detail.profile.headline)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                                Text("来自\(detail.profile.hometown)")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                                Text(detail.profile.bio)
                                    .font(.body)
                                    .foregroundStyle(DSColor.title)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("联系方式") {
                        if detail.profile.isContactVisible {
                            if let qq = detail.profile.qq, !qq.isEmpty {
                                Text("QQ：\(qq)")
                            }
                            if let wechat = detail.profile.wechat, !wechat.isEmpty {
                                Text("微信：\(wechat)")
                            }
                            if (detail.profile.qq ?? "").isEmpty && (detail.profile.wechat ?? "").isEmpty {
                                Text("对方暂未填写 QQ 或微信")
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        } else {
                            Text("对方还没有向你公开联系方式，互相确认后会展示在这里。")
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }

                    Section("撩一下") {
                        if detail.isPickNotAvailable && !detail.profile.isContactVisible {
                            Text("你已经发过请求了，等待对方处理即可。")
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        } else if detail.profile.isContactVisible {
                            Text("你们已经互相确认，联系方式现在已可见。")
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        } else {
                            TextField("说点什么吧，不超过 50 字", text: $pickContent, axis: .vertical)
                                .lineLimit(3...5)

                            Button {
                                Task { await submitPick() }
                            } label: {
                                if isSubmittingPick {
                                    ProgressView()
                                } else {
                                    Text("发送请求")
                                }
                            }
                            .disabled(isSubmittingPick || pickContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }

                    if let actionMessage {
                        Section {
                            Text(actionMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.primary)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadDetail()
                }
            }
        }
        .navigationTitle("资料详情")
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(profileID: profileID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "卖室友详情加载失败"
        }
    }

    private func submitPick() async {
        let normalizedContent = pickContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedContent.isEmpty else {
            actionMessage = "请输入想说的话"
            return
        }
        guard normalizedContent.count <= 50 else {
            actionMessage = "撩一下内容不能超过 50 个字"
            return
        }

        isSubmittingPick = true
        defer { isSubmittingPick = false }

        do {
            try await viewModel.submitPick(profileID: profileID, content: normalizedContent)
            actionMessage = "请求已发送"
            pickContent = ""
            await loadDetail()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "发送失败"
        }
    }
}

private struct PublishDatingView: View {
    @ObservedObject var listViewModel: DatingHallViewModel
    @StateObject private var viewModel: PublishDatingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(
        listViewModel: DatingHallViewModel,
        viewModel: PublishDatingViewModel
    ) {
        self.listViewModel = listViewModel
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                if let image = viewModel.image {
                    ZStack(alignment: .topTrailing) {
                        previewImageView(image)

                        Button {
                            viewModel.image = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, DSColor.danger)
                        }
                        .offset(x: 6, y: -6)
                    }
                } else {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                            Text("添加照片")
                                .font(.caption)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Text("照片为选填，只展示第一张。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("资料照片")
            }

            Section {
                TextField("昵称", text: $viewModel.nickname)
                Picker("年级", selection: $viewModel.selectedGrade) {
                    ForEach(1 ..< 5) { grade in
                        Text(gradeText(grade)).tag(grade)
                    }
                }
                Picker("展示分区", selection: $viewModel.selectedArea) {
                    ForEach(DatingArea.allCases) { area in
                        Text(area.title).tag(area)
                    }
                }
                Picker("学院", selection: $viewModel.selectedFaculty) {
                    ForEach(viewModel.facultyOptions, id: \.self) { faculty in
                        Text(faculty).tag(faculty)
                    }
                }
                TextField("家乡", text: $viewModel.hometown)
                TextField("QQ（选填）", text: $viewModel.qq)
                TextField("微信（选填）", text: $viewModel.wechat)
                TextField("自我介绍（100字内）", text: $viewModel.content, axis: .vertical)
                    .lineLimit(4...6)
            } header: {
                Text("资料内容")
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle("发布资料")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if viewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text("提交")
                    }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await loadSelectedImage(from: newItem) }
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.submitState.isSuccess },
            set: { isPresented in
                if !isPresented {
                    viewModel.submitState = .idle
                }
            }
        )) {
            Button("知道了") {
                viewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
        .task {
            await viewModel.loadFacultyOptionsIfNeeded()
        }
    }

    private func publish() async {
        guard let draft = viewModel.buildDraft() else { return }

        viewModel.submitState = .submitting

        do {
            try await listViewModel.publish(draft: draft)
            viewModel.submitState = .success("资料已发布，稍后会出现在大厅中")
        } catch {
            viewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
        }
    }

    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { return }

        let contentType = item.supportedContentTypes.first
        let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
        let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
        viewModel.image = UploadImageAsset(
            fileName: "dating-\(UUID().uuidString).\(fileExtension)",
            mimeType: mimeType,
            data: data
        )
        selectedPhotoItem = nil
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
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DSColor.subtitle)
                    }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func gradeText(_ grade: Int) -> String {
        switch grade {
        case 1:
            return "大一"
        case 2:
            return "大二"
        case 3:
            return "大三"
        default:
            return "大四"
        }
    }
}

#Preview {
    let container = AppContainer.preview
    NavigationStack {
        DatingView(viewModel: DatingHallViewModel(repository: MockDatingRepository()))
    }
    .environmentObject(container)
}
