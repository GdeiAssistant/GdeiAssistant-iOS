import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel: NewsViewModel

    init(viewModel: NewsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                DSLoadingView(text: "正在加载新闻通知...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.items.isEmpty {
                DSEmptyStateView(icon: "newspaper", title: "暂无新闻通知", message: "当前没有可展示的资讯内容")
            } else {
                List {
                    ForEach(viewModel.items) { item in
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
                            VStack(alignment: .leading, spacing: 8) {
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
        .navigationTitle("新闻通知")
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
        NewsView(viewModel: NewsViewModel(repository: MockNewsRepository()))
            .environmentObject(AppContainer.preview)
    }
}
