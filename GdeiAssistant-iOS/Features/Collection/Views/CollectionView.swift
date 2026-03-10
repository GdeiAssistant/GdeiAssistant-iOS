import SwiftUI

struct CollectionView: View {
    @StateObject private var viewModel: CollectionViewModel
    @State private var showBorrowSheet = false
    @State private var borrowPassword = ""

    init(viewModel: CollectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    TextField("搜索馆藏书名、作者", text: $viewModel.keyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("查询") {
                        Task { await viewModel.search() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            } header: {
                Text("馆藏检索")
            }

            Section {
                Button {
                    showBorrowSheet = true
                    Task { await viewModel.loadBorrowedBooks(password: nil) }
                } label: {
                    Label("我的借阅", systemImage: "books.vertical")
                }
            } header: {
                Text("借阅服务")
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: "正在查询馆藏...")
                }
            } else if viewModel.searchPage.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "magnifyingglass", title: "暂无检索结果", message: "输入书名、作者后开始查询")
                }
            } else {
                Section {
                    ForEach(viewModel.searchPage.items) { item in
                        Button {
                            Task { await viewModel.loadDetail(for: item) }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(DSColor.title)
                                Text(item.author)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                                Text(item.publisher)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("检索结果")
                }
            }
        }
        .navigationTitle("馆藏")
        .overlay {
            if viewModel.isDetailLoading {
                DSLoadingView(text: "正在加载详情...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .sheet(item: $viewModel.selectedDetail) { detail in
            CollectionDetailSheet(detail: detail)
        }
        .sheet(isPresented: $showBorrowSheet) {
            NavigationStack {
                List {
                    Section {
                        SecureFormField(title: "图书馆密码（选填）", placeholder: "用于真实账号查询", text: $borrowPassword)
                        Button("刷新借阅记录") {
                            Task { await viewModel.loadBorrowedBooks(password: borrowPassword) }
                        }
                        .disabled(viewModel.isBorrowLoading)
                        if let borrowMessage = viewModel.borrowMessage {
                            Text(borrowMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.danger)
                        }
                    } header: {
                        Text("借阅查询")
                    }

                    if viewModel.isBorrowLoading {
                        Section {
                            DSLoadingView(text: "正在加载借阅记录...")
                        }
                    } else if viewModel.borrowedBooks.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "books.vertical", title: "暂无借阅记录", message: "可重新加载或稍后再试")
                        }
                    } else {
                        Section {
                            ForEach(viewModel.borrowedBooks) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.title)
                                            .font(.headline)
                                        Spacer()
                                        Button("续借") {
                                            Task { await viewModel.renewBorrow(item: item) }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    Text(item.author)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                    Text("借阅：\(item.borrowDate)  应还：\(item.returnDate)  续借：\(item.renewCount) 次")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("借阅列表")
                        }
                    }
                }
                .navigationTitle("我的借阅")
                .alert("提示", isPresented: Binding(
                    get: { viewModel.submitState.message != nil },
                    set: { if !$0 { viewModel.submitState = .idle } }
                )) {
                    Button("知道了", role: .cancel) {}
                } message: {
                    Text(viewModel.submitState.message ?? "")
                }
            }
        }
    }
}

private struct CollectionDetailSheet: View {
    let detail: CollectionDetailInfo

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(detail.author)
                    Text(detail.publisher)
                    Text(detail.principal)
                    Text(detail.price)
                } header: {
                    Text(detail.title)
                }

                Section {
                    Text(detail.physicalDescription)
                    Text("主题词：\(detail.subjectTheme)")
                    Text("分类号：\(detail.classification)")
                } header: {
                    Text("书目信息")
                }

                Section {
                    ForEach(detail.distributions) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.location)
                                .font(.headline)
                            Text("索书号：\(item.callNumber)")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Text("条码：\(item.barcode)  状态：\(item.state)")
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }
                } header: {
                    Text("馆藏分布")
                }
            }
            .navigationTitle("馆藏详情")
        }
    }
}

#Preview {
    NavigationStack {
        CollectionView(viewModel: CollectionViewModel(repository: MockCollectionRepository()))
    }
}
