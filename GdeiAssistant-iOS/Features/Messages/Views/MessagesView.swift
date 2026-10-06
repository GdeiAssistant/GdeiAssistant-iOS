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

    init(viewModel: MessagesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isInitialLoading {
                    DSLoadingView(text: localizedString("messages.loading"))
                } else if !viewModel.hasAnyContent && viewModel.hasAnyError {
                    DSErrorStateView(message: viewModel.primaryErrorMessage) {
                        Task { await viewModel.refresh() }
                    }
                } else {
                    content
                }
            }
            .navigationTitle(localizedString("messages.title"))
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.md) {
                directMessagePanel
                newsPanel
                systemNoticePanel
                festivalPanel
                interactionPanel
            }
            .padding(DSSpacing.md)
            .padding(.bottom, DSSpacing.xl)
        }
        .dsScreenBackground()
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var directMessagePanel: some View {
        overviewSectionCard(
            title: localizedString("social.conversations.title"),
            systemImage: "bubble.left.and.bubble.right.fill",
            tint: DSColor.primary,
            titleAccessibilityIdentifier: "messages.section.directMessage"
        ) {
            NavigationLink {
                ConversationListView(viewModel: container.makeConversationListViewModel())
            } label: {
                moreChip
            }
            .buttonStyle(.plain)
        } content: {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(localizedString("social.conversations.entryHint"))
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Layout.overviewHeaderHorizontalInset)
                    .padding(.vertical, Layout.sectionRowVerticalPadding)

                NavigationLink {
                    SocialUserSearchView(viewModel: container.makeSocialUserSearchViewModel())
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(localizedString("social.search.title"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.primary)
                    .padding(.horizontal, Layout.overviewHeaderHorizontalInset)
                    .padding(.bottom, Layout.sectionRowVerticalPadding)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var newsPanel: some View {
        overviewSectionCard(
            title: localizedString("messages.newsSection"),
            systemImage: "newspaper.fill",
            tint: DSColor.primary,
            titleAccessibilityIdentifier: "messages.section.news"
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
                sectionEmptyRow(title: localizedString("messages.noNews"), systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.newsItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider(leadingInset: Layout.overviewHeaderHorizontalInset)
                        }
                        NavigationLink {
                            NewsDetailView(
                                newsID: item.id,
                                fallbackTitle: item.title,
                                fallbackContent: item.content,
                                fallbackPublishDate: item.publishDate,
                                fallbackType: item.type,
                                fallbackSourceURL: item.sourceURL
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

    private var systemNoticePanel: some View {
        overviewSectionCard(
            title: localizedString("messages.systemNoticeSection"),
            systemImage: "megaphone.fill",
            tint: DSColor.warning,
            titleAccessibilityIdentifier: "messages.section.system"
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
                sectionEmptyRow(title: localizedString("messages.noSystemNotice"), systemImage: "tray")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.systemNoticeItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            cardDivider(leadingInset: Layout.overviewHeaderHorizontalInset)
                        }
                        NavigationLink {
                            AnnouncementDetailView(
                                navigationTitleText: localizedString("messages.systemNoticeSection"),
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

    @ViewBuilder
    private var festivalPanel: some View {
        if let festival = viewModel.festival {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(DSColor.primary)
                        Text(festival.name)
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                    }
                    ForEach(festival.description, id: \.self) { line in
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    }
                }
            }
        }
    }

    private var interactionPanel: some View {
        sectionCard(
            title: localizedString("messages.interactionSection"),
            systemImage: "bubble.left.and.bubble.right.fill",
            tint: DSColor.primary,
            titleAccessibilityIdentifier: "messages.section.interaction"
        ) {
            HStack(spacing: DSSpacing.xs) {
                if viewModel.interactionUnreadCount > 0 {
                    headerMetaChip(title: String(format: localizedString("messages.unreadCount"), viewModel.interactionUnreadCount), tint: DSColor.primary)
                    headerActionButton(title: localizedString("messages.markAllRead"), tint: DSColor.primary) {
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
                sectionEmptyRow(title: localizedString("messages.noInteraction"), systemImage: "tray")
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
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .center, spacing: Layout.overviewHeaderIconTitleSpacing) {
                        DSRadius.controlShape
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
                            .applyAccessibilityIdentifier(titleAccessibilityIdentifier)
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
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    DSRadius.controlShape
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
                        .applyAccessibilityIdentifier(titleAccessibilityIdentifier)
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
            .accessibilityIdentifier("messages.interaction.\(item.id)")
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                Task { await viewModel.markNotificationRead(notificationID: item.id) }
            })
        } else {
            notificationRow(item)
                .accessibilityIdentifier("messages.interaction.\(item.id)")
        }
    }

    private func newsRow(_ item: NewsItem) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(item.sourceTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DSColor.primary)
            Text(item.title)
                .font(.headline)
                .foregroundStyle(DSColor.title)
            Text(item.content)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .lineLimit(3)
            Text(item.publishDate)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.overviewHeaderHorizontalInset)
        .padding(.vertical, Layout.sectionRowVerticalPadding)
    }

    private func systemNoticeRow(_ item: AppNotificationItem) -> some View {
        standardTextRow(
            title: item.title,
            summary: item.message,
            dateText: item.createdAt
        )
    }

    private func standardTextRow(title: String, summary: String, dateText: String) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
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

        return HStack(alignment: .top, spacing: DSSpacing.sm) {
            DSRadius.controlShape
                .fill(iconSpec.tint.opacity(0.14))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: iconSpec.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(iconSpec.tint)
                }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack(alignment: .top, spacing: DSSpacing.xs) {
                    if item.isInteractionItem && !item.isRead {
                        Circle()
                            .fill(DSColor.primary)
                            .frame(width: 8, height: 8)
                            .padding(.top, DSSpacing.xs)
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

                HStack(spacing: DSSpacing.xs) {
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
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
    }

    private func headerMetaChip(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func headerActionButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var moreChip: some View {
        Text(localizedString("messages.more"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DSColor.subtitle)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(DSColor.subtitle.opacity(0.12))
            .clipShape(Capsule())
    }

    private func badge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func sectionLoadingRow() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, DSSpacing.md)
            Spacer()
        }
    }

    private func sectionEmptyRow(title: String, systemImage: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(DSColor.subtitle)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DSSpacing.md)
    }

    private func sectionRetryRow(message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DSSpacing.xs) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                Text(localizedString("messages.tapRetry"))
                    .font(.caption)
                    .foregroundStyle(DSColor.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.md)
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
            return NotificationIconSpec(systemImage: "bubble.left.fill", tint: DSColor.primary)
        case .express:
            return NotificationIconSpec(systemImage: "heart.text.square.fill", tint: DSColor.warning)
        case .topic:
            return NotificationIconSpec(systemImage: "text.bubble.fill", tint: DSColor.primary)
        case .photograph:
            return NotificationIconSpec(systemImage: "camera.fill", tint: DSColor.primary)
        case .datingCenter:
            return NotificationIconSpec(systemImage: "person.2.fill", tint: DSColor.primary)
        case nil:
            switch item.category {
            case .system:
                return NotificationIconSpec(systemImage: "bell.badge.fill", tint: DSColor.warning)
            case .service:
                return NotificationIconSpec(systemImage: "book.closed.fill", tint: DSColor.primary)
            case .comment, .like, .interaction:
                return NotificationIconSpec(systemImage: "bubble.left.and.bubble.right.fill", tint: DSColor.primary)
            case .all:
                return NotificationIconSpec(systemImage: "bell.fill", tint: DSColor.subtitle)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
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
