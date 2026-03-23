import SwiftUI

struct InteractionMessagesListView: View {
    @StateObject private var viewModel: InteractionMessageListViewModel

    init(viewModel: InteractionMessageListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                DSLoadingView(text: localizedString("messages.interactionLoading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.items.isEmpty {
                DSEmptyStateView(icon: "bubble.left.and.bubble.right", title: localizedString("messages.noInteractionEmpty"), message: localizedString("messages.noInteractionMessage"))
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        interactionRow(item)
                            .task {
                                await viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                    }

                    if viewModel.isLoadingMore {
                        loadingMoreRow
                    } else if let loadMoreErrorMessage = viewModel.loadMoreErrorMessage {
                        loadMoreErrorRow(message: loadMoreErrorMessage) {
                            if let lastItem = viewModel.items.last {
                                Task { await viewModel.loadMoreIfNeeded(currentItem: lastItem) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle(localizedString("messages.interactionTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.interactionUnreadCount > 0 {
                    Button(localizedString("messages.markAllReadButton")) {
                        Task { await viewModel.markAllNotificationsRead() }
                    }
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private func interactionRow(_ item: AppNotificationItem) -> some View {
        if item.destination != nil {
            NavigationLink {
                MessageNavigationDestinationView(item: item)
            } label: {
                interactionContent(item)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                Task { await viewModel.markNotificationRead(notificationID: item.id) }
            })
        } else {
            interactionContent(item)
        }
    }

    private func interactionContent(_ item: AppNotificationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if !item.isRead {
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
            }

            Text(item.message)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)
                .lineLimit(3)

            HStack(spacing: 8) {
                if let moduleBadge = item.moduleBadgeText {
                    badge(title: moduleBadge, tint: DSColor.subtitle)
                }
                if let actionBadge = item.actionBadgeText {
                    badge(title: actionBadge, tint: DSColor.primary)
                }
                if let readBadge = item.readBadgeText {
                    badge(title: readBadge, tint: item.isRead ? DSColor.subtitle : DSColor.primary)
                }
            }
        }
        .padding(.vertical, 6)
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

    private var loadingMoreRow: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 8)
            Spacer()
        }
        .listRowSeparator(.hidden)
    }

    private func loadMoreErrorRow(message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                Text(localizedString("messages.tapRetry"))
                    .font(.caption)
                    .foregroundStyle(DSColor.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NavigationStack {
        InteractionMessagesListView(
            viewModel: InteractionMessageListViewModel(repository: MockMessagesRepository())
        )
        .environmentObject(AppContainer.preview)
    }
}
