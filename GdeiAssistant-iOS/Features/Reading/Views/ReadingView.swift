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
                DSEmptyStateView(icon: "newspaper", title: "暂无专题阅读", message: "稍后再来看看最新内容")
            } else {
                List(viewModel.items) { item in
                    Button {
                        if let url = URL(string: item.link), !item.link.isEmpty {
                            openURL(url)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(DSColor.title)
                            Text(item.summary)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                                .lineLimit(2)
                            Text(item.createdAt)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
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
}

#Preview {
    NavigationStack {
        ReadingView(viewModel: ReadingViewModel(repository: MockReadingRepository()))
    }
}
