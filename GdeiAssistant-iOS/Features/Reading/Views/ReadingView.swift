import SwiftUI

struct ReadingView: View {
    @StateObject private var viewModel: ReadingViewModel
    @Environment(\.openURL) private var openURL

    init(viewModel: ReadingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                DSLoadingView(text: "正在加载专题阅读...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.items.isEmpty {
                DSEmptyStateView(icon: "book.pages", title: "暂无专题阅读", message: "稍后再来看看最新内容")
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        Button {
                            if let url = URL(string: item.link), !item.link.isEmpty {
                                openURL(url)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(DSColor.title)
                                Text(item.summary)
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
        .navigationTitle("专题阅读")
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
        ReadingView(viewModel: ReadingViewModel(repository: MockReadingRepository()))
    }
}
