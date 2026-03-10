import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel: NewsViewModel

    init(viewModel: NewsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("分类", selection: $viewModel.selectedCategory) {
                    ForEach(NewsCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedCategory) { _, _ in
                    Task { await viewModel.refresh() }
                }
            }

            if viewModel.isLoading && viewModel.items.isEmpty {
                Section {
                    DSLoadingView(text: "正在加载新闻通知...")
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "newspaper", title: "暂无通知", message: "当前分类暂无新闻数据")
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        Button {
                            viewModel.selectedItem = item
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(DSColor.title)
                                Text(item.publishDate)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("新闻通知")
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $viewModel.selectedItem) { item in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                        Text(item.publishDate)
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                        Text(item.content)
                            .font(.body)
                            .foregroundStyle(DSColor.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }
                .navigationTitle("通知详情")
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewsView(viewModel: NewsViewModel(repository: MockNewsRepository()))
    }
}
