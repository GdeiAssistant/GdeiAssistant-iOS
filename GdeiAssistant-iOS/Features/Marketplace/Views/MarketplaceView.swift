import SwiftUI
import PhotosUI
import UIKit

struct MarketplaceView: View {
    @StateObject private var viewModel: MarketplaceViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: MarketplaceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                typeSelector
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if viewModel.isLoading && viewModel.items.isEmpty {
                Section {
                    DSLoadingView(text: "正在加载二手交易...")
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "bag", title: "暂无二手交易信息", message: "当前分类下还没有内容")
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            MarketplaceDetailView(viewModel: viewModel, itemID: item.id)
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
                                        Text("¥\(item.price, specifier: "%.2f")")
                                            .font(.headline)
                                            .foregroundStyle(DSColor.primary)
                                    }

                                    Text(item.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                        .lineLimit(2)

                                    HStack {
                                        Text(item.sellerName)
                                        Spacer()
                                        Text(item.location)
                                        Text(item.postedAt)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
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
        .navigationTitle(AppDestination.marketplace.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MarketplaceProfileView(viewModel: viewModel)
                }

                NavigationLink("发布") {
                    PublishMarketplaceView(
                        listViewModel: viewModel,
                        publishViewModel: container.makePublishMarketplaceViewModel()
                    )
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(title: "全部", isSelected: viewModel.selectedTypeID == nil) {
                    Task {
                        viewModel.selectedTypeID = nil
                        await viewModel.refresh()
                    }
                }

                ForEach(viewModel.typeOptions, id: \.id) { option in
                    filterChip(title: option.title, isSelected: viewModel.selectedTypeID == option.id) {
                        Task {
                            viewModel.selectedTypeID = option.id
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : DSColor.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? DSColor.primary : DSColor.primary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct MarketplaceProfileView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @State private var summary: MarketplacePersonalSummary?
    @State private var selectedTab: MarketplaceProfileTab = .doing
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingDetail: MarketplaceDetail?
    @State private var pendingStateChange: MarketplaceStateChangeContext?
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
                MarketplaceProfileSummaryView(
                    summary: summary,
                    selectedTab: $selectedTab,
                    actionMessage: actionMessage,
                    actionsProvider: actions(for:),
                    onOpen: { itemID in
                        Task { await openDetail(itemID) }
                    },
                    onAction: { action, item in
                        handleAction(action, item: item)
                    }
                )
                .refreshable {
                    await loadData()
                }
            }
        }
        .navigationTitle("个人中心")
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditMarketplaceView(
                    listViewModel: viewModel,
                    viewModel: EditMarketplaceViewModel(detail: detail)
                ) {
                    await loadData()
                }
            }
        }
        .confirmationDialog("确认更新商品状态？", isPresented: Binding(
            get: { pendingStateChange != nil },
            set: { if !$0 { pendingStateChange = nil } }
        )) {
            if let pendingStateChange {
                Button(pendingStateChange.buttonTitle, role: pendingStateChange.role) {
                    Task { await updateState(pendingStateChange) }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .task {
            await loadData()
        }
    }

    private func items(for summary: MarketplacePersonalSummary) -> [MarketplaceItem] {
        switch selectedTab {
        case .doing:
            return summary.doing
        case .sold:
            return summary.sold
        case .off:
            return summary.off
        }
    }

    private func actions(for item: MarketplaceItem) -> [MarketplaceProfileAction] {
        switch selectedTab {
        case .doing:
            return [.edit, .offShelf, .sold]
        case .sold:
            return [.edit, .putBack]
        case .off:
            return []
        }
    }

    private func handleAction(_ action: MarketplaceProfileAction, item: MarketplaceItem) {
        switch action {
        case .edit:
            Task { await openDetail(item.id, forEditing: true) }
        case .offShelf:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .offShelf)
        case .sold:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .sold)
        case .putBack:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .selling)
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

    private func updateState(_ context: MarketplaceStateChangeContext) async {
        defer { pendingStateChange = nil }
        do {
            try await viewModel.updateState(itemID: context.itemID, state: context.state)
            actionMessage = context.successMessage
            await loadData()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "操作失败"
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

private struct MarketplaceProfileSummaryView: View {
    let summary: MarketplacePersonalSummary
    @Binding var selectedTab: MarketplaceProfileTab
    let actionMessage: String?
    let actionsProvider: (MarketplaceItem) -> [MarketplaceProfileAction]
    let onOpen: (String) -> Void
    let onAction: (MarketplaceProfileAction, MarketplaceItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                MarketplaceProfileHeaderView(summary: summary)
                MarketplaceProfileTabSelector(selectedTab: $selectedTab)

                if let actionMessage {
                    DSCard {
                        Text(actionMessage)
                            .font(.footnote)
                            .foregroundStyle(DSColor.primary)
                    }
                }

                if currentItems.isEmpty {
                    DSEmptyStateView(icon: "bag", title: selectedTab.emptyTitle, message: selectedTab.emptyMessage)
                } else {
                    VStack(spacing: 10) {
                        ForEach(currentItems, id: \.id) { item in
                            MarketplaceProfileItemCard(
                                item: item,
                                actions: actionsProvider(item),
                                onOpen: { onOpen(item.id) },
                                onAction: { action in
                                    onAction(action, item)
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
    }

    private var currentItems: [MarketplaceItem] {
        switch selectedTab {
        case .doing:
            return summary.doing
        case .sold:
            return summary.sold
        case .off:
            return summary.off
        }
    }
}

private struct MarketplaceProfileHeaderView: View {
    let summary: MarketplacePersonalSummary

    var body: some View {
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
}

private struct MarketplaceProfileTabSelector: View {
    @Binding var selectedTab: MarketplaceProfileTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MarketplaceProfileTab.allCases) { tab in
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
}

private enum MarketplaceProfileTab: String, CaseIterable, Identifiable {
    case doing
    case sold
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doing:
            return "正在出售"
        case .sold:
            return "已出售"
        case .off:
            return "已下架"
        }
    }

    var emptyTitle: String {
        switch self {
        case .doing:
            return "暂无正在出售的商品"
        case .sold:
            return "暂无已出售的商品"
        case .off:
            return "暂无已下架的商品"
        }
    }

    var emptyMessage: String {
        switch self {
        case .doing:
            return "去发布一件想出手的闲置"
        case .sold:
            return "已完成交易的商品会出现在这里"
        case .off:
            return "暂时没有下架中的商品"
        }
    }
}

private struct MarketplaceProfileItemCard: View {
    let item: MarketplaceItem
    let actions: [MarketplaceProfileAction]
    let onOpen: () -> Void
    let onAction: (MarketplaceProfileAction) -> Void

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: onOpen) {
                    HStack(alignment: .top, spacing: 12) {
                        if item.previewImageURL != nil {
                            DSRemoteImageView(urlString: item.previewImageURL)
                                .frame(width: 72, height: 72)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(DSColor.title)
                            Text("¥\(item.price, specifier: "%.2f")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.primary)
                            Text(item.postedAt)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                if !actions.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(actions) { action in
                            if action.isPrimary {
                                Button(action.title, role: action.role) {
                                    onAction(action)
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button(action.title, role: action.role) {
                                    onAction(action)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
    }
}

private enum MarketplaceProfileAction: String, CaseIterable, Identifiable {
    case edit
    case offShelf
    case sold
    case putBack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .edit:
            return "编辑"
        case .offShelf:
            return "下架"
        case .sold:
            return "确认售出"
        case .putBack:
            return "上架"
        }
    }

    var isPrimary: Bool {
        self == .sold || self == .putBack
    }

    var role: ButtonRole? {
        self == .offShelf ? .destructive : nil
    }
}

private struct MarketplaceStateChangeContext: Identifiable {
    let itemID: String
    let state: MarketplaceItemState

    var id: String { "\(itemID)-\(state.rawValue)" }

    var buttonTitle: String {
        switch state {
        case .offShelf:
            return "确认下架"
        case .sold:
            return "确认售出"
        case .selling:
            return "确认上架"
        case .systemDeleted:
            return "确认"
        }
    }

    var role: ButtonRole? {
        state == .offShelf ? .destructive : nil
    }

    var successMessage: String {
        switch state {
        case .offShelf:
            return "商品已下架"
        case .sold:
            return "商品已标记为售出"
        case .selling:
            return "商品已重新上架"
        case .systemDeleted:
            return "状态已更新"
        }
    }
}

struct MarketplaceDetailView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    let itemID: String
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    @State private var detail: MarketplaceDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var isSubmitting = false
    @State private var editingDetail: MarketplaceDetail?
    @State private var confirmState: MarketplaceItemState?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载商品详情...")
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

                            HStack {
                                Text(detail.item.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(DSColor.title)
                                Spacer()
                                Text("¥\(detail.item.price, specifier: "%.2f")")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(DSColor.primary)
                            }

                            Text(detail.description)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.title)
                                .lineSpacing(4)

                            Divider()

                            HStack(spacing: 12) {
                                DSAvatarView(urlString: detail.item.sellerAvatarURL, size: 52)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(detail.sellerNickname ?? detail.item.sellerName)
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)
                                    Text(sellerMetaText(detail))
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }

                            infoRow(title: "卖家", value: detail.item.sellerName)
                            infoRow(title: "状态", value: detail.item.state.title)
                            infoRow(title: "分类", value: detail.condition)
                            infoRow(title: "地点", value: detail.item.location)
                            infoRow(title: "联系说明", value: detail.contactHint)
                        }

                        if isOwnedByCurrentUser(detail) {
                            DSCard {
                                if let resultMessage {
                                    Text(resultMessage)
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.primary)
                                }

                                if detail.item.state == .selling {
                                    Button("编辑商品信息") {
                                        editingDetail = detail
                                    }
                                    .buttonStyle(.bordered)

                                    Button(isSubmitting ? "处理中..." : "标记已出售") {
                                        confirmState = .sold
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSubmitting)

                                    Button("下架商品", role: .destructive) {
                                        confirmState = .offShelf
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isSubmitting)
                                } else {
                                    Text("当前商品已不在大厅展示。若需重新发布，请按 Web 现有能力走发布流程。")
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
        .navigationTitle("商品详情")
        .confirmationDialog("确认更新商品状态？", isPresented: Binding(
            get: { confirmState != nil },
            set: { if !$0 { confirmState = nil } }
        )) {
            if let confirmState {
                Button(confirmState.title, role: confirmState == .offShelf ? .destructive : nil) {
                    Task { await updateState(confirmState) }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditMarketplaceView(
                    listViewModel: viewModel,
                    viewModel: EditMarketplaceViewModel(detail: detail)
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "商品详情加载失败"
        }
    }

    private func isOwnedByCurrentUser(_ detail: MarketplaceDetail) -> Bool {
        guard let currentUsername = container.sessionState.currentUser?.username else { return false }
        return detail.sellerUsername == currentUsername
    }

    private func updateState(_ state: MarketplaceItemState) async {
        isSubmitting = true
        defer {
            isSubmitting = false
            confirmState = nil
        }

        do {
            try await viewModel.updateState(itemID: itemID, state: state)
            resultMessage = "商品状态已更新"
            dismiss()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "状态更新失败"
        }
    }

    private func infoRow(title: String, value: String) -> some View {
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

    private func sellerMetaText(_ detail: MarketplaceDetail) -> String {
        [detail.sellerCollege, detail.sellerMajor, detail.sellerGrade]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
}

struct PublishMarketplaceView: View {
    @ObservedObject var listViewModel: MarketplaceViewModel
    @StateObject private var publishViewModel: PublishMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(
        listViewModel: MarketplaceViewModel,
        publishViewModel: PublishMarketplaceViewModel
    ) {
        self.listViewModel = listViewModel
        _publishViewModel = StateObject(wrappedValue: publishViewModel)
    }

    var body: some View {
        Form {
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

                Text("请至少上传 1 张图片，最多 4 张。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("商品图片")
            }

            Section {
                TextField("商品名称", text: $publishViewModel.title)
                TextField("价格", text: $publishViewModel.priceText)
                    .keyboardType(.decimalPad)
                Picker("商品分类", selection: $publishViewModel.selectedTypeID) {
                    ForEach(Array(publishViewModel.typeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                TextField("商品描述（100字内）", text: $publishViewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField("交易地点", text: $publishViewModel.location)
                TextField("附加标签，空格分隔", text: $publishViewModel.tagsText)
            } header: {
                Text("商品信息")
            }

            Section {
                TextField("QQ 号", text: $publishViewModel.qq)
                    .keyboardType(.numberPad)
                TextField("手机号（选填）", text: $publishViewModel.phone)
                    .keyboardType(.numberPad)
                Text("后端真实接口要求至少提供 QQ，手机号为补充联系方式。")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("联系方式")
            }

            if let failureMessage = publishViewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .navigationTitle("发布商品")
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
            publishViewModel.submitState = .success("商品已发布，稍后会出现在列表中")
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
                fileName: "market-\(UUID().uuidString).\(fileExtension)",
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

private struct EditMarketplaceView: View {
    @ObservedObject var listViewModel: MarketplaceViewModel
    @StateObject private var viewModel: EditMarketplaceViewModel
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        listViewModel: MarketplaceViewModel,
        viewModel: EditMarketplaceViewModel,
        onSaved: @escaping () async -> Void
    ) {
        self.listViewModel = listViewModel
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                TextField("商品名称", text: $viewModel.title)
                TextField("价格", text: $viewModel.priceText)
                    .keyboardType(.decimalPad)
                Picker("商品分类", selection: $viewModel.selectedTypeID) {
                    ForEach(Array(viewModel.typeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                TextField("商品描述（100字内）", text: $viewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField("交易地点", text: $viewModel.location)
            } header: {
                Text("商品信息")
            }

            Section {
                TextField("QQ 号", text: $viewModel.qq)
                    .keyboardType(.numberPad)
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
        .navigationTitle("编辑商品")
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
            viewModel.submitState = .success("商品信息已更新")
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
        MarketplaceView(viewModel: MarketplaceViewModel(repository: MockMarketplaceRepository()))
            .environmentObject(container)
    }
}
