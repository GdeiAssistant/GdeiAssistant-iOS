import SwiftUI
import PhotosUI
import UIKit

struct LostFoundView: View {
    @StateObject private var viewModel: LostFoundViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: LostFoundViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                DSLoadingView(text: "正在加载失物招领...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.items.isEmpty {
                DSEmptyStateView(icon: "shippingbox.circle", title: "暂无失物招领信息", message: "可以先发布一条信息")
            } else {
                List(viewModel.items) { item in
                    NavigationLink {
                        LostFoundDetailView(viewModel: viewModel, itemID: item.id)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            if item.previewImageURL != nil {
                                DSRemoteImageView(urlString: item.previewImageURL)
                                    .frame(width: 84, height: 84)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)
                                    Spacer()
                                    Text(item.type.displayName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(item.type == .lost ? DSColor.warning : DSColor.secondary)
                                }

                                Text(item.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                                    .lineLimit(2)

                                HStack {
                                    Text(item.location)
                                    Spacer()
                                    Text(item.createdAt)
                                }
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
        .navigationTitle("失物招领")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    LostFoundProfileView(viewModel: viewModel)
                }

                NavigationLink("发布") {
                    PublishLostFoundView(
                        listViewModel: viewModel,
                        publishViewModel: container.makePublishLostFoundViewModel()
                    )
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct LostFoundProfileView: View {
    @ObservedObject var viewModel: LostFoundViewModel
    @State private var summary: LostFoundPersonalSummary?
    @State private var selectedTab: LostFoundProfileTab = .lost
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingDetail: LostFoundDetail?
    @State private var markTargetID: String?
    @State private var actionMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载个人中心...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if let summary {
                ScrollView {
                    VStack(spacing: 14) {
                        profileHeader(summary)
                        tabSelector
                        content(summary)
                    }
                    .padding(16)
                }
                .background(DSColor.background)
                .refreshable {
                    await loadData()
                }
            }
        }
        .navigationTitle("个人中心")
        .confirmationDialog("确认标记为已找回？", isPresented: Binding(
            get: { markTargetID != nil },
            set: { if !$0 { markTargetID = nil } }
        )) {
            Button("确认寻回") {
                if let markTargetID {
                    Task { await markDidFound(markTargetID) }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditLostFoundView(
                    listViewModel: viewModel,
                    viewModel: EditLostFoundViewModel(detail: detail)
                ) {
                    await loadData()
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(LostFoundProfileTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.title)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? DSColor.primary : DSColor.subtitle)
                        Rectangle()
                            .fill(selectedTab == tab ? DSColor.primary : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func content(_ summary: LostFoundPersonalSummary) -> some View {
        if let actionMessage {
            DSCard {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(DSColor.primary)
            }
        }

        let items = items(for: summary)
        if items.isEmpty {
            DSEmptyStateView(icon: "shippingbox.circle", title: selectedTab.emptyTitle, message: selectedTab.emptyMessage)
        } else {
            VStack(spacing: 10) {
                ForEach(items) { item in
                    DSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                Task { await openDetail(item.id) }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    if item.previewImageURL != nil {
                                        DSRemoteImageView(urlString: item.previewImageURL)
                                            .frame(width: 72, height: 72)
                                    }
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                        Text(item.createdAt)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                        Text(item.type.displayName)
                                            .font(.caption)
                                            .foregroundStyle(item.type == .lost ? DSColor.warning : DSColor.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            if selectedTab != .didFound {
                                HStack(spacing: 10) {
                                    Button("编辑") {
                                        Task { await openDetail(item.id, forEditing: true) }
                                    }
                                    .buttonStyle(.bordered)

                                    Button("确认寻回") {
                                        markTargetID = item.id
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func profileHeader(_ summary: LostFoundPersonalSummary) -> some View {
        HStack(alignment: .center, spacing: 14) {
            DSAvatarView(urlString: summary.avatarURL, size: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.nickname)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(summary.introduction)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.27, green: 0.76, blue: 0.65))
        )
    }

    private func items(for summary: LostFoundPersonalSummary) -> [LostFoundItem] {
        switch selectedTab {
        case .lost:
            return summary.lost
        case .found:
            return summary.found
        case .didFound:
            return summary.didFound
        }
    }

    private func openDetail(_ itemID: String, forEditing: Bool = false) async {
        do {
            let detail = try await viewModel.fetchDetail(itemID: itemID)
            if forEditing {
                editingDetail = detail
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func markDidFound(_ itemID: String) async {
        defer { markTargetID = nil }
        do {
            try await viewModel.markDidFound(itemID: itemID)
            actionMessage = "状态已更新"
            await loadData()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "更新失败"
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            summary = try await viewModel.fetchMySummary()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "个人中心加载失败"
        }
    }
}

private enum LostFoundProfileTab: String, CaseIterable, Identifiable {
    case lost
    case found
    case didFound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lost:
            return "失物"
        case .found:
            return "招领"
        case .didFound:
            return "确认寻回"
        }
    }

    var emptyTitle: String {
        switch self {
        case .lost:
            return "暂无失物信息"
        case .found:
            return "暂无招领信息"
        case .didFound:
            return "暂无确认寻回信息"
        }
    }

    var emptyMessage: String {
        switch self {
        case .lost:
            return "遗失信息会展示在这里"
        case .found:
            return "拾到并发布的信息会展示在这里"
        case .didFound:
            return "确认寻回后的内容会保留在这里"
        }
    }
}

struct LostFoundDetailView: View {
    @ObservedObject var viewModel: LostFoundViewModel
    let itemID: String
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    @State private var detail: LostFoundDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var isSubmitting = false
    @State private var editingDetail: LostFoundDetail?
    @State private var confirmDidFound = false

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
                    VStack(spacing: 16) {
                        DSCard {
                            if !detail.imageURLs.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(detail.imageURLs, id: \.self) { imageURL in
                                            DSRemoteImageView(urlString: imageURL)
                                                .frame(width: 220, height: 160)
                                        }
                                    }
                                }
                            }

                            Text(detail.item.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(DSColor.title)

                            Text(detail.description)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.title)
                                .lineSpacing(4)

                            Divider()

                            HStack(spacing: 12) {
                                DSAvatarView(urlString: detail.ownerAvatarURL, size: 52)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(detail.ownerNickname ?? "发布者")
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)
                                    Text(detail.ownerUsername ?? "发布者")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }

                            detailRow(title: "类型", value: detail.item.type.displayName)
                            detailRow(title: "地点", value: detail.item.location)
                            detailRow(title: "联系说明", value: detail.contactHint)
                            detailRow(title: "状态", value: detail.statusText)
                        }

                        if isOwnedByCurrentUser(detail) {
                            DSCard {
                                if let resultMessage {
                                    Text(resultMessage)
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.primary)
                                }

                                if detail.item.state == .active {
                                    Button("编辑信息") {
                                        editingDetail = detail
                                    }
                                    .buttonStyle(.bordered)

                                    Button(isSubmitting ? "处理中..." : "标记已找回") {
                                        confirmDidFound = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSubmitting)
                                } else {
                                    Text("该信息已完成找回，不再展示在大厅列表。")
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(DSColor.background)
            }
        }
        .navigationTitle("详情")
        .confirmationDialog("确认标记为已找回？", isPresented: $confirmDidFound) {
            Button("确认已找回") {
                Task { await markDidFound() }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditLostFoundView(
                    listViewModel: viewModel,
                    viewModel: EditLostFoundViewModel(detail: detail)
                ) {
                    await loadDetail()
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(itemID: itemID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func isOwnedByCurrentUser(_ detail: LostFoundDetail) -> Bool {
        guard let currentUsername = container.sessionState.currentUser?.username else { return false }
        return detail.ownerUsername == currentUsername
    }

    private func markDidFound() async {
        isSubmitting = true
        defer {
            isSubmitting = false
            confirmDidFound = false
        }

        do {
            try await viewModel.markDidFound(itemID: itemID)
            resultMessage = "状态已更新"
            dismiss()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "更新失败"
        }
    }

    private func detailRow(title: String, value: String) -> some View {
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

struct PublishLostFoundView: View {
    @ObservedObject var listViewModel: LostFoundViewModel
    @StateObject private var publishViewModel: PublishLostFoundViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(
        listViewModel: LostFoundViewModel,
        publishViewModel: PublishLostFoundViewModel
    ) {
        self.listViewModel = listViewModel
        _publishViewModel = StateObject(wrappedValue: publishViewModel)
    }

    var body: some View {
        Form {
            Section {
                Picker("寻找类型", selection: $publishViewModel.selectedType) {
                    ForEach(LostFoundType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                Picker("物品分类", selection: $publishViewModel.selectedItemTypeID) {
                    ForEach(Array(publishViewModel.itemTypeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }

                TextField("物品名称", text: $publishViewModel.title)
                TextField("物品描述（100字内）", text: $publishViewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField(publishViewModel.selectedType == .lost ? "丢失地点" : "捡到地点", text: $publishViewModel.location)
            } header: {
                Text("基础信息")
            }

            Section {
                TextField("QQ 号（选填）", text: $publishViewModel.qq)
                    .keyboardType(.numberPad)
                TextField("微信号（选填）", text: $publishViewModel.wechat)
                TextField("手机号（选填）", text: $publishViewModel.phone)
                    .keyboardType(.numberPad)
                Text("QQ / 微信 / 手机号至少填写一项。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("联系方式")
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(publishViewModel.images) { image in
                            ZStack(alignment: .topTrailing) {
                                previewImageView(image)

                                Button {
                                    publishViewModel.removeImage(id: image.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, DSColor.danger)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }

                        if publishViewModel.images.count < 4 {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 4 - publishViewModel.images.count,
                                matching: .images
                            ) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title3)
                                    Text("添加图片")
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
                Text("最多可上传 4 张图片。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("图片")
            }

            if let failureMessage = publishViewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .navigationTitle("发布信息")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if publishViewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text("提交")
                    }
                }
                .disabled(publishViewModel.submitState.isSubmitting || !publishViewModel.isFormValid)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadSelectedImages(from: newItems) }
        }
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = publishViewModel.submitState {
                    return true
                }
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
    }

    private func publish() async {
        guard let draft = publishViewModel.buildDraft() else { return }

        publishViewModel.submitState = .submitting

        do {
            try await listViewModel.publish(draft: draft)
            publishViewModel.submitState = .success("信息已发布，稍后会出现在列表中")
        } catch {
            publishViewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
        }
    }

    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for item in items {
            guard publishViewModel.images.count < 4 else { break }
            guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { continue }

            let contentType = item.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let image = UploadImageAsset(
                fileName: "lostfound-\(UUID().uuidString).\(fileExtension)",
                mimeType: mimeType,
                data: data
            )
            publishViewModel.addImage(image)
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
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DSColor.subtitle)
                    }
            }
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct EditLostFoundView: View {
    @ObservedObject var listViewModel: LostFoundViewModel
    @StateObject private var viewModel: EditLostFoundViewModel
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        listViewModel: LostFoundViewModel,
        viewModel: EditLostFoundViewModel,
        onSaved: @escaping () async -> Void
    ) {
        self.listViewModel = listViewModel
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                Picker("寻找类型", selection: $viewModel.selectedType) {
                    ForEach(LostFoundType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                Picker("物品分类", selection: $viewModel.selectedItemTypeID) {
                    ForEach(Array(viewModel.itemTypeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }

                TextField("物品名称", text: $viewModel.title)
                TextField("物品描述（100字内）", text: $viewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField(viewModel.selectedType == .lost ? "丢失地点" : "捡到地点", text: $viewModel.location)
            } header: {
                Text("基础信息")
            }

            Section {
                TextField("QQ 号（选填）", text: $viewModel.qq)
                    .keyboardType(.numberPad)
                TextField("微信号（选填）", text: $viewModel.wechat)
                TextField("手机号（选填）", text: $viewModel.phone)
                    .keyboardType(.numberPad)
            } header: {
                Text("联系方式")
            }

            if let failureMessage = viewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .navigationTitle("编辑信息")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? "保存中..." : "保存") {
                    Task { await submit() }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
    }

    private func submit() async {
        guard let draft = viewModel.buildDraft() else { return }
        viewModel.submitState = .submitting

        do {
            try await listViewModel.update(itemID: viewModel.itemID, draft: draft)
            viewModel.submitState = .success("信息已更新")
            await onSaved()
            dismiss()
        } catch {
            viewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? "保存失败")
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        LostFoundView(viewModel: LostFoundViewModel(repository: MockLostFoundRepository()))
            .environmentObject(container)
    }
}
