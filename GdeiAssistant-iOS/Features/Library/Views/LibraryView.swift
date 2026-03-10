import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(viewModel: LibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            content
        }
        .navigationTitle("我的图书馆")
        .toolbar {
            NavigationLink("我的借阅") {
                MyBorrowView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            TextField("搜索书名 / 作者", text: $viewModel.keyword)
                .textFieldStyle(.roundedBorder)

            Button("搜索") {
                Task { await viewModel.searchBooks() }
            }
            .buttonStyle(.borderedProminent)
            .tint(DSColor.primary)
        }
        .padding(16)
        .background(DSColor.background)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.books.isEmpty {
            DSLoadingView(text: "正在检索图书...")
        } else if let errorMessage = viewModel.errorMessage, viewModel.books.isEmpty {
            DSErrorStateView(message: errorMessage) {
                Task { await viewModel.refreshAll() }
            }
        } else if viewModel.books.isEmpty {
            DSEmptyStateView(icon: "books.vertical", title: "暂无匹配图书", message: "换个关键词试试")
        } else {
            List(viewModel.books) { book in
                NavigationLink {
                    LibraryBookDetailView(viewModel: viewModel, bookID: book.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.title)
                        Text("\(book.author) · \(book.location)")
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                        Text("可借数量：\(book.availableCount)")
                            .font(.caption)
                            .foregroundStyle(book.availableCount > 0 ? DSColor.secondary : DSColor.danger)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refreshAll()
            }
        }
    }
}

struct LibraryBookDetailView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let bookID: String

    @State private var detail: LibraryBookDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: "正在加载详情...")
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                ScrollView {
                    DSCard {
                        Text(detail.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DSColor.title)
                        Text("作者：\(detail.author)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("出版社：\(detail.publisher)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("ISBN：\(detail.isbn)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("馆藏位置：\(detail.location)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text("可借数量：\(detail.availableCount)")
                            .font(.subheadline)
                            .foregroundStyle(detail.availableCount > 0 ? DSColor.secondary : DSColor.danger)

                        Divider()
                        Text(detail.summary)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.title)
                            .lineSpacing(4)
                    }
                    .padding(16)
                }
                .background(DSColor.background)
            }
        }
        .navigationTitle("图书详情")
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchBookDetail(bookID: bookID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }
}

struct MyBorrowView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        Group {
            if viewModel.borrowRecords.isEmpty {
                DSEmptyStateView(icon: "book.closed", title: "暂无借阅记录", message: "你还没有借阅图书")
            } else {
                List(viewModel.borrowRecords) { record in
                    NavigationLink {
                        BorrowRecordDetailView(viewModel: viewModel, record: record)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.bookTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.title)

                            Text("借阅：\(record.borrowDate)  到期：\(record.dueDate)")
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)

                            HStack {
                                Text(record.status)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.secondary)

                                Spacer()

                                Text(record.renewable ? "可续借" : "不可续借")
                                    .font(.caption)
                                    .foregroundStyle(record.renewable ? DSColor.primary : DSColor.subtitle)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("我的借阅")
    }
}

struct BorrowRecordDetailView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let record: BorrowRecord

    @State private var showPasswordSheet = false
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    Text(record.bookTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DSColor.title)

                    infoRow(title: "借阅日期", value: record.borrowDate)
                    infoRow(title: "应还日期", value: record.dueDate)
                    infoRow(title: "当前状态", value: record.status)
                    infoRow(title: "续借凭据", value: record.renewable ? "已获取 sn / code" : "不可续借")
                }

                DSCard {
                    Text("续借说明")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Text("续借前需要输入图书馆密码进行二次校验。密码仅用于本次请求，不会写入本地。")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(4)

                    DSButton(
                        title: "续借图书",
                        icon: "arrow.clockwise",
                        isLoading: viewModel.submitState.isSubmitting,
                        isDisabled: !record.renewable
                    ) {
                        showPasswordSheet = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle("借阅详情")
        .sheet(isPresented: $showPasswordSheet, onDismiss: { password = "" }) {
            PasswordInputSheet(
                title: "图书续借",
                message: "请输入图书馆密码完成续借校验。续借需要后端同时校验借阅凭据和账号密码。",
                placeholder: "请输入图书馆密码",
                confirmTitle: "确认续借",
                keyboardType: .default,
                isSubmitting: viewModel.submitState.isSubmitting,
                errorMessage: {
                    if case .failure(let message) = viewModel.submitState { return message }
                    return nil
                }(),
                password: $password,
                onCancel: {
                    showPasswordSheet = false
                },
                onConfirm: {
                    Task {
                        await viewModel.renewBorrow(record: record, password: password)
                        if case .success = viewModel.submitState {
                            showPasswordSheet = false
                            password = ""
                        }
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = viewModel.submitState {
                    return true
                }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearSubmitState()
                }
            }
        )) {
            Button("知道了") {
                viewModel.clearSubmitState()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .foregroundStyle(DSColor.title)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        LibraryView(viewModel: LibraryViewModel(repository: MockLibraryRepository()))
    }
}
