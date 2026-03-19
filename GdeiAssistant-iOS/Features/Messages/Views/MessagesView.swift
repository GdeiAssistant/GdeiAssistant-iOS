import SwiftUI

struct MessagesView: View {
    private enum Layout {
        static let sectionLeading: CGFloat = 16
        static let sectionTrailing: CGFloat = 16
        static let sectionHeaderVerticalPadding: CGFloat = 16
        static let overviewHeaderHorizontalInset: CGFloat = 18
        static let overviewHeaderIconSize: CGFloat = 24
        static let overviewHeaderIconTitleSpacing: CGFloat = 8
        static let overviewHeaderMinHeight: CGFloat = 24
        static let overviewTextLeading: CGFloat =
            overviewHeaderHorizontalInset + overviewHeaderIconSize + overviewHeaderIconTitleSpacing
        static let interactionHeaderIconSize: CGFloat = 40
        static let interactionHeaderIconTitleSpacing: CGFloat = 12
        static let sectionRowVerticalPadding: CGFloat = 14
    }

    @StateObject private var viewModel: MessagesViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.openURL) private var openURL

    init(viewModel: MessagesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isInitialLoading {
                    DSLoadingView(text: "正在加载资讯信息...")
                } else if !viewModel.hasAnyContent && viewModel.hasAnyError {
                    DSErrorStateView(message: viewModel.primaryErrorMessage) {
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
        ScrollView {
            LazyVStack(spacing: 16) {
                newsPanel
                readingPanel
                systemNoticePanel
                interactionPanel
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(DSColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var newsPanel: some View {
        overviewSectionCard(
            title: "新闻通知",
            systemImage: "newspaper.fill",
            tint: DSColor.primary
        ) {
            NavigationLink {
                NewsView(viewModel: container.makeNewsViewModel())
            } label: {
                moreChip
            }
            .buttonStyle(.plain)
        } content: {
            if viewModel.isNewsLoading && viewModel.newsItems.isEmpty {
                sectionLoadingRow()
            } else if let errorMessage = viewModel.newsErrorMessage, viewModel.newsItems.isEmpty {
                sectionRetryRow(message: errorMessage) {
                    Task { await viewModel.refreshNews() }
                }
            } else if viewModel.newsItems.isEmpty {
                sectionEmptyRow(title: "暂无新闻通知", systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.newsItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider(leadingInset: Layout.overviewHeaderHorizontalInset)
                        }
                        NavigationLink {
                            AnnouncementDetailView(
                                navigationTitleText: "新闻通知",
                                announcementID: item.id,
                                fallbackTitle: item.title,
                                fallbackContent: item.content,
                                fallbackCreatedAt: item.publishDate
                            )
                        } label: {
                            newsRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var readingPanel: some View {
        overviewSectionCard(
            title: "阅读",
            systemImage: "book.pages.fill",
            tint: DSColor.secondary
        ) {
            NavigationLink {
                ReadingView(viewModel: container.makeReadingViewModel())
            } label: {
                moreChip
            }
            .buttonStyle(.plain)
        } content: {
            if viewModel.isReadingLoading && viewModel.readingItems.isEmpty {
                sectionLoadingRow()
            } else if let errorMessage = viewModel.readingErrorMessage, viewModel.readingItems.isEmpty {
                sectionRetryRow(message: errorMessage) {
                    Task { await viewModel.refreshReading() }
                }
            } else if viewModel.readingItems.isEmpty {
                sectionEmptyRow(title: "暂无阅读内容", systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.readingItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider(leadingInset: Layout.overviewHeaderHorizontalInset)
                        }
                        Button {
                            if let url = URL(string: item.link), !item.link.isEmpty {
                                openURL(url)
                            }
                        } label: {
                            readingRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var systemNoticePanel: some View {
        overviewSectionCard(
            title: "系统通知公告",
            systemImage: "megaphone.fill",
            tint: DSColor.warning
        ) {
            NavigationLink {
                SystemNoticeListView(viewModel: container.makeSystemNoticeListViewModel())
            } label: {
                moreChip
            }
            .buttonStyle(.plain)
        } content: {
            if viewModel.isSystemLoading && viewModel.systemNoticeItems.isEmpty {
                sectionLoadingRow()
            } else if let errorMessage = viewModel.systemErrorMessage, viewModel.systemNoticeItems.isEmpty {
                sectionRetryRow(message: errorMessage) {
                    Task { await viewModel.refreshSystemNotices() }
                }
            } else if viewModel.systemNoticeItems.isEmpty {
                sectionEmptyRow(title: "暂无系统通知公告", systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.systemNoticeItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider(leadingInset: Layout.overviewHeaderHorizontalInset)
                        }
                        NavigationLink {
                            AnnouncementDetailView(
                                navigationTitleText: "系统通知公告",
                                announcementID: item.targetID ?? item.id,
                                fallbackTitle: item.title,
                                fallbackContent: item.message,
                                fallbackCreatedAt: item.createdAt
                            )
                        } label: {
                            systemNoticeRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var interactionPanel: some View {
        sectionCard(
            title: "互动消息",
            systemImage: "bubble.left.and.bubble.right.fill",
            tint: DSColor.primary
        ) {
            HStack(spacing: 8) {
                if viewModel.interactionUnreadCount > 0 {
                    headerMetaChip(title: "\(viewModel.interactionUnreadCount) 未读", tint: DSColor.primary)
                    headerActionButton(title: "全部已读", tint: DSColor.primary) {
                        Task { await viewModel.markAllInteractionNotificationsRead() }
                    }
                }

                NavigationLink {
                    InteractionMessagesListView(viewModel: container.makeInteractionMessageListViewModel())
                } label: {
                    moreChip
                }
                .buttonStyle(.plain)
            }
        } content: {
            if viewModel.isInteractionLoading && viewModel.interactionNoticeItems.isEmpty {
                sectionLoadingRow()
            } else if let errorMessage = viewModel.interactionErrorMessage, viewModel.interactionNoticeItems.isEmpty {
                sectionRetryRow(message: errorMessage) {
                    Task { await viewModel.refreshInteractionItems() }
                }
            } else if viewModel.interactionNoticeItems.isEmpty {
                sectionEmptyRow(title: "暂无互动消息", systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.interactionNoticeItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider()
                        }
                        overviewInteractionRow(item)
                    }
                }
            }
        }
    }

    private func overviewSectionCard<Accessory: View, Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .center, spacing: Layout.overviewHeaderIconTitleSpacing) {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(tint.opacity(0.14))
                            .frame(width: Layout.overviewHeaderIconSize, height: Layout.overviewHeaderIconSize)
                            .overlay {
                                Image(systemName: systemImage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(tint)
                            }

                        Text(title)
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                    }

                    Spacer(minLength: 12)

                    accessory()
                }
                .frame(minHeight: Layout.overviewHeaderMinHeight)
                .padding(.horizontal, Layout.overviewHeaderHorizontalInset)
                .padding(.vertical, Layout.sectionHeaderVerticalPadding)

                content()
            }
        }
    }

    private func sectionCard<Accessory: View, Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: Layout.interactionHeaderIconSize, height: Layout.interactionHeaderIconSize)
                        .overlay {
                            Image(systemName: systemImage)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(tint)
                        }

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                        .padding(.leading, Layout.interactionHeaderIconTitleSpacing)

                    Spacer(minLength: 12)

                    accessory()
                }
                .padding(.leading, Layout.sectionLeading)
                .padding(.trailing, Layout.sectionTrailing)
                .padding(.vertical, Layout.sectionHeaderVerticalPadding)

                content()
            }
        }
    }

    @ViewBuilder
    private func overviewInteractionRow(_ item: AppNotificationItem) -> some View {
        if item.destination != nil {
            NavigationLink {
                MessageNavigationDestinationView(item: item)
            } label: {
                notificationRow(item)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                Task { await viewModel.markNotificationRead(notificationID: item.id) }
            })
        } else {
            notificationRow(item)
        }
    }

    private func newsRow(_ item: NewsItem) -> some View {
        standardTextRow(
            title: item.title,
            summary: item.content,
            dateText: item.publishDate
        )
    }

    private func readingRow(_ item: ReadingItem) -> some View {
        standardTextRow(
            title: item.title,
            summary: item.summary,
            dateText: item.createdAt
        )
    }

    private func systemNoticeRow(_ item: AppNotificationItem) -> some View {
        standardTextRow(
            title: item.title,
            summary: item.message,
            dateText: item.createdAt
        )
    }

    private func standardTextRow(title: String, summary: String, dateText: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DSColor.title)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .lineLimit(3)
            Text(dateText)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.overviewHeaderHorizontalInset)
        .padding(.vertical, Layout.sectionRowVerticalPadding)
    }

    private func notificationRow(_ item: AppNotificationItem) -> some View {
        let iconSpec = notificationIconSpec(for: item)

        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconSpec.tint.opacity(0.14))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: iconSpec.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(iconSpec.tint)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    if item.isInteractionItem && !item.isRead {
                        Circle()
                            .fill(DSColor.primary)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }

                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.createdAt)
                        .font(.caption)
                        .foregroundStyle(DSColor.subtitle)
                        .fixedSize()
                }

                Text(item.message)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    if let moduleBadgeText = item.moduleBadgeText {
                        badge(title: moduleBadgeText, tint: DSColor.subtitle)
                    }
                    if let actionBadgeText = item.actionBadgeText {
                        badge(title: actionBadgeText, tint: DSColor.primary)
                    }
                    if let readBadgeText = item.readBadgeText {
                        badge(title: readBadgeText, tint: item.isRead ? DSColor.subtitle : DSColor.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func headerMetaChip(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func headerActionButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var moreChip: some View {
        Text("更多")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DSColor.subtitle)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DSColor.subtitle.opacity(0.12))
            .clipShape(Capsule())
    }

    private func badge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func sectionLoadingRow() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 18)
            Spacer()
        }
    }

    private func sectionEmptyRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(DSColor.subtitle)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 18)
    }

    private func sectionRetryRow(message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                Text("点击重试")
                    .font(.caption)
                    .foregroundStyle(DSColor.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    private func cardDivider(leadingInset: CGFloat = Layout.sectionLeading) -> some View {
        Divider()
            .padding(.leading, leadingInset)
            .padding(.trailing, Layout.sectionTrailing)
    }

    private func notificationIconSpec(for item: AppNotificationItem) -> NotificationIconSpec {
        switch item.destination {
        case .announcement:
            return NotificationIconSpec(systemImage: "megaphone.fill", tint: DSColor.warning)
        case .news:
            return NotificationIconSpec(systemImage: "newspaper.fill", tint: DSColor.primary)
        case .marketplace:
            return NotificationIconSpec(systemImage: "bag.fill", tint: DSColor.warning)
        case .lostFound:
            return NotificationIconSpec(systemImage: "mappin.and.ellipse", tint: DSColor.warning)
        case .delivery:
            return NotificationIconSpec(systemImage: "shippingbox.fill", tint: DSColor.primary)
        case .secret:
            return NotificationIconSpec(systemImage: "bubble.left.fill", tint: DSColor.secondary)
        case .express:
            return NotificationIconSpec(systemImage: "heart.text.square.fill", tint: DSColor.warning)
        case .topic:
            return NotificationIconSpec(systemImage: "text.bubble.fill", tint: DSColor.primary)
        case .photograph:
            return NotificationIconSpec(systemImage: "camera.fill", tint: DSColor.secondary)
        case .datingCenter:
            return NotificationIconSpec(systemImage: "person.2.fill", tint: DSColor.secondary)
        case nil:
            switch item.category {
            case .system:
                return NotificationIconSpec(systemImage: "bell.badge.fill", tint: DSColor.warning)
            case .service:
                return NotificationIconSpec(systemImage: "book.closed.fill", tint: DSColor.secondary)
            case .comment, .like, .interaction:
                return NotificationIconSpec(systemImage: "bubble.left.and.bubble.right.fill", tint: DSColor.primary)
            case .all:
                return NotificationIconSpec(systemImage: "bell.fill", tint: DSColor.subtitle)
            }
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return MessagesView(viewModel: container.makeMessagesViewModel())
        .environmentObject(container)
}

private struct NotificationIconSpec {
    let systemImage: String
    let tint: Color
}
