import SwiftUI

struct DatingView: View {
    @StateObject private var viewModel: DatingCenterViewModel

    init(viewModel: DatingCenterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        DatingCenterContent(viewModel: viewModel, navigationTitle: "卖室友")
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

#Preview {
    NavigationStack {
        DatingView(viewModel: DatingCenterViewModel(repository: MockDatingRepository()))
    }
}
