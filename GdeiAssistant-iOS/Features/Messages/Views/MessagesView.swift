import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel: MessagesViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: MessagesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty && viewModel.threads.isEmpty {
                    DSLoadingView(text: "正在加载资讯信息...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty && viewModel.threads.isEmpty {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                } else {
                    content
                }
            }
            .navigationTitle("资讯信息")
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    private var content: some View {
        List {
            Section("新闻 / 阅读") {
                infoEntryLink(
                    title: "新闻通知",
                    subtitle: "查看校园新闻与通知列表",
                    systemImage: "newspaper"
                ) {
                    NewsView(viewModel: container.makeNewsViewModel())
                }

                infoEntryLink(
                    title: "阅读",
                    subtitle: "查看阅读专题与内容推荐",
                    systemImage: "book.pages"
                ) {
                    ReadingView(viewModel: container.makeReadingViewModel())
                }

                if !viewModel.campusInfoItems.isEmpty {
                    ForEach(viewModel.campusInfoItems) { item in
                        navigationWrappedNotificationRow(item)
                    }
                }
            }

            Section("系统通知 / 公告") {
                if viewModel.systemNoticeItems.isEmpty {
                    Text("暂无系统通知")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                } else {
                    ForEach(viewModel.systemNoticeItems) { item in
                        navigationWrappedNotificationRow(item)
                    }
                }
            }

            Section("互动消息") {
                if !viewModel.interactionNoticeItems.isEmpty {
                    ForEach(viewModel.interactionNoticeItems) { item in
                        navigationWrappedNotificationRow(item)
                    }
                }

                if viewModel.threads.isEmpty {
                    Text("暂无互动消息")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                } else {
                    ForEach(viewModel.threads) { thread in
                        NavigationLink {
                            DatingCenterView(
                                viewModel: container.makeDatingCenterViewModel(initialTab: thread.destinationTab)
                            )
                            .task {
                                await viewModel.markThreadRead(threadID: thread.id)
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                DSAvatarView(urlString: thread.avatarURL, size: 40)

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top) {
                                        Text(thread.title)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                        Spacer()
                                        Text(thread.updatedAt)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                    }

                                    Text(thread.lastMessage)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)

                                    HStack {
                                        Text(thread.isRead ? "已读" : "未读")
                                            .font(.caption)
                                            .foregroundStyle(thread.isRead ? DSColor.subtitle : DSColor.primary)
                                        Spacer()
                                        if thread.unreadCount > 0 {
                                            Text("\(thread.unreadCount)")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(DSColor.danger)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func infoEntryLink<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(DSColor.primary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func notificationRow(_ item: AppNotificationItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                Spacer()
                Text(item.createdAt)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            }

            Text(item.message)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func navigationWrappedNotificationRow(_ item: AppNotificationItem) -> some View {
        if let destination = item.destination {
            NavigationLink {
                destinationView(for: item, destination: destination)
            } label: {
                notificationRow(item)
            }
            .buttonStyle(.plain)
        } else {
            notificationRow(item)
        }
    }

    @ViewBuilder
    private func destinationView(for item: AppNotificationItem, destination: MessageNavigationTarget) -> some View {
        switch destination {
        case .news:
            NewsView(viewModel: container.makeNewsViewModel())
        case .reading:
            ReadingView(viewModel: container.makeReadingViewModel())
        case .marketplace:
            if let targetID = item.targetID {
                MarketplaceDetailView(viewModel: container.makeMarketplaceViewModel(), itemID: targetID)
            } else {
                MarketplaceView(viewModel: container.makeMarketplaceViewModel())
            }
        case .lostFound:
            if let targetID = item.targetID {
                LostFoundDetailView(viewModel: container.makeLostFoundViewModel(), itemID: targetID)
            } else {
                LostFoundView(viewModel: container.makeLostFoundViewModel())
            }
        case .delivery:
            if let targetID = item.targetID {
                DeliveryDetailView(viewModel: container.makeDeliveryViewModel(), orderID: targetID, dismissAfterMutation: false)
            } else {
                DeliveryView(viewModel: container.makeDeliveryViewModel())
            }
        case .secret:
            if let targetID = item.targetID {
                SecretDetailView(viewModel: container.makeSecretViewModel(), postID: targetID)
            } else {
                SecretView(viewModel: container.makeSecretViewModel())
            }
        case .express:
            if let targetID = item.targetID {
                ExpressDetailView(viewModel: container.makeExpressViewModel(), postID: targetID)
            } else {
                ExpressView(viewModel: container.makeExpressViewModel())
            }
        case .topic:
            if let targetID = item.targetID {
                TopicDetailView(viewModel: container.makeTopicViewModel(), postID: targetID)
            } else {
                TopicView(viewModel: container.makeTopicViewModel())
            }
        case .photograph:
            if let targetID = item.targetID {
                PhotographDetailView(viewModel: container.makePhotographViewModel(), postID: targetID)
            } else {
                PhotographView(viewModel: container.makePhotographViewModel())
            }
        case .datingReceived:
            DatingCenterView(
                viewModel: container.makeDatingCenterViewModel(
                    initialTab: .received,
                    focusedPickID: item.targetID,
                    focusedProfileID: item.targetSubID
                )
            )
        case .datingSent:
            DatingCenterView(
                viewModel: container.makeDatingCenterViewModel(
                    initialTab: .sent,
                    focusedPickID: item.targetID,
                    focusedProfileID: item.targetSubID
                )
            )
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return MessagesView(viewModel: MessagesViewModel(repository: MockMessagesRepository()))
        .environmentObject(container)
}
