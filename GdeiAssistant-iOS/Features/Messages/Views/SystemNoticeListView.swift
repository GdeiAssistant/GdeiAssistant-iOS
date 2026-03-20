import SwiftUI

struct SystemNoticeListView: View {
    @StateObject private var viewModel: SystemNoticeListViewModel

    init(viewModel: SystemNoticeListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                DSLoadingView(text: "正在加载系统公告...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.items.isEmpty {
                DSEmptyStateView(icon: "megaphone", title: "暂无系统公告", message: "稍后再来查看最新公告")
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            AnnouncementDetailView(
                                navigationTitleText: "系统公告",
                                announcementID: item.targetID ?? item.id,
                                fallbackTitle: item.title,
                                fallbackContent: item.message,
                                fallbackCreatedAt: item.createdAt
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(DSColor.title)
                                Text(item.message)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                                    .lineLimit(3)
                                Text(item.createdAt)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
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
        .navigationTitle("系统公告")
        .task {
            await viewModel.loadIfNeeded()
        }
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
                Text("点击重试")
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
        SystemNoticeListView(
            viewModel: SystemNoticeListViewModel(repository: MockMessagesRepository())
        )
        .environmentObject(AppContainer.preview)
    }
}
