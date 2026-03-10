import SwiftUI
import PhotosUI
import UIKit

struct DatingView: View {
    @StateObject private var viewModel: DatingViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: DatingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("区域", selection: $viewModel.selectedArea) {
                ForEach(DatingArea.allCases) { area in
                    Text(area.title).tag(area)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .onChange(of: viewModel.selectedArea) { _, _ in
                Task { await viewModel.refresh() }
            }

            content
        }
        .background(DSColor.background)
        .navigationTitle("卖室友")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    DatingCenterView(viewModel: container.makeDatingCenterViewModel())
                }
                NavigationLink("发布") {
                    PublishDatingView(viewModel: PublishDatingViewModel(repository: container.datingRepository), listViewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.profiles.isEmpty {
            DSLoadingView(text: "正在加载卖室友资料...")
        } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty {
            DSErrorStateView(message: errorMessage) {
                Task { await viewModel.refresh() }
            }
        } else if viewModel.profiles.isEmpty {
            DSEmptyStateView(icon: "person.3", title: "暂无匹配内容", message: "稍后再来看看")
        } else {
            List(viewModel.profiles) { profile in
                NavigationLink {
                    DatingProfileView(viewModel: viewModel, profileID: profile.id)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        DSAvatarView(urlString: profile.imageURL, size: 52)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(profile.nickname)
                                    .font(.headline)
                                    .foregroundStyle(DSColor.title)
                                Spacer()
                                Text(profile.grade)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }

                            Text(profile.headline)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.primary)

                            Text("\(profile.college) · 来自\(profile.hometown)")
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

private struct DatingProfileView: View {
    @ObservedObject var viewModel: DatingViewModel
    let profileID: String

    @State private var detail: DatingProfileDetail?
    @State private var pickContent = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var resultMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载资料...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadProfile() }
                }
            } else if let detail {
                ScrollView {
                    VStack(spacing: 14) {
                        DSCard {
                            HStack(spacing: 12) {
                                DSAvatarView(urlString: detail.profile.imageURL, size: 68)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(detail.profile.nickname)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(DSColor.title)

                                    Text(detail.profile.headline)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.primary)

                                    Text("\(detail.profile.grade) · \(detail.profile.college)")
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }

                            Text("家乡：\(detail.profile.hometown)")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)

                            Text(detail.profile.bio)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.title)
                                .lineSpacing(4)

                            VStack(alignment: .leading, spacing: 10) {
                                infoRow("QQ", value: detail.profile.isContactVisible ? (detail.profile.qq ?? "未填写") : "对方接受了撩一下后才可见哦")
                                infoRow("微信", value: detail.profile.isContactVisible ? (detail.profile.wechat ?? "未填写") : "对方接受了撩一下后才可见哦")
                            }

                            if detail.isPickNotAvailable {
                                Text("当前不能继续发送请求，请在互动中心查看状态。")
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }

                        DSCard {
                            TextField("来说点什么吧，不超过50字", text: $pickContent, axis: .vertical)
                                .lineLimit(3...5)
                            HStack {
                                Button(isSubmitting ? "发送中..." : "撩一下") {
                                    Task { await submitPick() }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isSubmitting || detail.isPickNotAvailable)
                            }
                            if let resultMessage {
                                Text(resultMessage)
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(DSColor.background)
            }
        }
        .navigationTitle("个人资料")
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(profileID: profileID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "资料加载失败"
        }
    }

    private func submitPick() async {
        let trimmed = FormValidationSupport.trimmed(pickContent)
        guard !trimmed.isEmpty else {
            resultMessage = "请输入撩一下的留言信息"
            return
        }
        if trimmed.count > 50 {
            resultMessage = "撩一下输入的内容太长了"
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await viewModel.sendPick(profileID: profileID, content: trimmed)
            pickContent = ""
            resultMessage = "发送成功，请耐心等待对方回复"
            await loadProfile()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "发送失败"
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(DSColor.title)
        }
        .font(.subheadline)
    }
}

private struct PublishDatingView: View {
    @StateObject private var viewModel: PublishDatingViewModel
    @ObservedObject var listViewModel: DatingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(viewModel: PublishDatingViewModel, listViewModel: DatingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.listViewModel = listViewModel
    }

    var body: some View {
        let photoButtonTitle = viewModel.image == nil ? "上传一张形象照（选填）" : "更换图片"

        Form {
            Section {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text(photoButtonTitle)
                    }
                }
                if let image = viewModel.image,
                   let uiImage = UIImage(data: image.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            } header: {
                Text("照片")
            }

            Section {
                TextField("昵称", text: $viewModel.nickname)
                Picker("年级", selection: $viewModel.grade) {
                    Text("大一").tag(1)
                    Text("大二").tag(2)
                    Text("大三").tag(3)
                    Text("大四").tag(4)
                }
                Picker("区域", selection: $viewModel.area) {
                    ForEach(DatingArea.allCases) { area in
                        Text(area.title).tag(area)
                    }
                }
                TextField("专业", text: $viewModel.faculty)
                TextField("家乡", text: $viewModel.hometown)
                TextField("QQ（选填）", text: $viewModel.qq)
                TextField("微信（选填）", text: $viewModel.wechat)
                TextField("理想对象描述", text: $viewModel.content, axis: .vertical)
                    .lineLimit(4...6)
            } header: {
                Text("发布信息")
            } footer: {
                Text("在接受撩一下请求前，QQ 和微信不会公开显示。")
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle("出卖室友")
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              !data.isEmpty else { return }
        let contentType = item.supportedContentTypes.first
        let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
        let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
        viewModel.image = UploadImageAsset(fileName: "dating-\(UUID().uuidString).\(fileExtension)", mimeType: mimeType, data: data)
    }
}

struct DatingCenterView: View {
    @StateObject private var viewModel: DatingCenterViewModel
    @State private var confirmHideID: String?
    @State private var highlightedItemID: String?

    init(viewModel: DatingCenterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
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
            .onChange(of: viewModel.selectedTab) { _, _ in
                scrollToFocusedItem(with: proxy)
            }
            .onChange(of: viewModel.receivedItems) { _, _ in
                scrollToFocusedItem(with: proxy)
            }
            .onChange(of: viewModel.sentItems) { _, _ in
                scrollToFocusedItem(with: proxy)
            }
            .onChange(of: viewModel.myPosts) { _, _ in
                scrollToFocusedItem(with: proxy)
            }
        }
        .navigationTitle("互动中心")
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .confirmationDialog("确定要隐藏这条发布吗？隐藏后他人将无法在大厅看到。", isPresented: Binding(
            get: { confirmHideID != nil },
            set: { if !$0 { confirmHideID = nil } }
        )) {
            Button("确认隐藏", role: .destructive) {
                if let confirmHideID {
                    Task { await viewModel.hideProfile(id: confirmHideID) }
                }
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
                        .id(item.id)
                        .listRowBackground(rowBackground(for: item.id))
                    }
                } header: {
                    Text("收到的撩")
                }
            }
        case .sent:
            if viewModel.isLoading && viewModel.sentItems.isEmpty {
                Section { DSLoadingView(text: "正在加载...") }
            } else if viewModel.sentItems.isEmpty {
                Section { DSEmptyStateView(icon: "paperplane", title: "暂无发出的请求", message: "去大厅看看心动对象") }
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
                        .id(item.id)
                        .listRowBackground(rowBackground(for: item.id))
                    }
                } header: {
                    Text("我发出的")
                }
            }
        case .posts:
            if viewModel.isLoading && viewModel.myPosts.isEmpty {
                Section { DSLoadingView(text: "正在加载...") }
            } else if viewModel.myPosts.isEmpty {
                Section { DSEmptyStateView(icon: "person.crop.square", title: "暂无发布", message: "去发布你的第一条信息") }
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
                                    Text(item.publishTime.isEmpty ? "已发布" : item.publishTime)
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
                        .id(item.id)
                        .listRowBackground(rowBackground(for: item.id))
                    }
                } header: {
                    Text("我的发布")
                }
            }
        }
    }

    private func scrollToFocusedItem(with proxy: ScrollViewProxy) {
        guard let focusID = viewModel.currentFocusID else { return }
        highlightedItemID = focusID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(focusID, anchor: .center)
            }
        }
    }

    private func rowBackground(for itemID: String) -> some View {
        Group {
            if highlightedItemID == itemID {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DSColor.primary.opacity(0.10))
            } else {
                Color.clear
            }
        }
    }
}

#Preview {
    NavigationStack {
        DatingView(viewModel: DatingViewModel(repository: MockDatingRepository()))
            .environmentObject(AppContainer.preview)
    }
}
