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
        .navigationTitle(LocalizedStringKey("library.title"))
        .toolbar {
            NavigationLink(LocalizedStringKey("library.myBorrow")) {
                MyBorrowView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            TextField(LocalizedStringKey("library.searchPlaceholder"), text: $viewModel.keyword)
                .textFieldStyle(.roundedBorder)

            Button(LocalizedStringKey("library.search")) {
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
            DSLoadingView(text: localizedString("library.loading"))
        } else if let errorMessage = viewModel.errorMessage, viewModel.books.isEmpty {
            DSErrorStateView(message: errorMessage) {
                Task { await viewModel.refreshAll() }
            }
        } else if viewModel.books.isEmpty {
            DSEmptyStateView(icon: "books.vertical", title: localizedString("library.emptyTitle"), message: localizedString("library.emptyMessage"))
        } else {
            VStack(spacing: 0) {
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
                            Text(localizedString("library.availableCount") + "\(book.availableCount)")
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

                HStack(spacing: 16) {
                    Button(LocalizedStringKey("library.previousPage")) {
                        Task { await viewModel.goToPreviousPage() }
                    }
                    .disabled(viewModel.currentPage <= 1)

                    Text(localizedString("library.pageIndicator") + "\(viewModel.currentPage)")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)

                    Button(LocalizedStringKey("library.nextPage")) {
                        Task { await viewModel.goToNextPage() }
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(DSColor.background)
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
                DSLoadingView(text: localizedString("library.detailLoading"))
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
                        Text(localizedString("library.detail.author") + detail.author)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(localizedString("library.detail.publisher") + detail.publisher)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(localizedString("library.detail.isbn") + detail.isbn)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(localizedString("library.detail.location") + detail.location)
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(localizedString("library.availableCount") + "\(detail.availableCount)")
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
        .navigationTitle(LocalizedStringKey("library.detail.title"))
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("library.detail.loadFailed")
        }
    }
}

struct MyBorrowView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        List {
            Section {
                SecureField(LocalizedStringKey("library.borrow.passwordPlaceholder"), text: $viewModel.borrowPassword)
                    .textContentType(.password)

                DSButton(
                    title: viewModel.hasLoadedBorrowRecords ? localizedString("library.borrow.refresh") : localizedString("library.borrow.query"),
                    icon: "arrow.clockwise",
                    isLoading: viewModel.isBorrowLoading
                ) {
                    Task { await viewModel.fetchBorrowRecords() }
                }

                Text(LocalizedStringKey("library.borrow.hint"))
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            }

            if let borrowErrorMessage = viewModel.borrowErrorMessage {
                Section {
                    DSErrorStateView(message: borrowErrorMessage) {
                        Task { await viewModel.fetchBorrowRecords() }
                    }
                }
            }

            if viewModel.isBorrowLoading && viewModel.borrowRecords.isEmpty {
                Section {
                    DSLoadingView(text: localizedString("library.borrow.loading"))
                }
            } else if !viewModel.hasLoadedBorrowRecords {
                Section {
                    DSEmptyStateView(icon: "book.closed", title: localizedString("library.borrow.notQueried"), message: localizedString("library.borrow.notQueriedMessage"))
                }
            } else if viewModel.borrowRecords.isEmpty {
                Section {
                    DSEmptyStateView(icon: "book.closed", title: localizedString("library.borrow.emptyTitle"), message: localizedString("library.borrow.emptyMessage"))
                }
            } else {
                Section(localizedString("library.borrow.list")) {
                    ForEach(viewModel.borrowRecords) { record in
                        NavigationLink {
                            BorrowRecordDetailView(viewModel: viewModel, record: record)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(record.bookTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DSColor.title)

                                Text(localizedString("library.borrow.borrowDate") + record.borrowDate + "  " + localizedString("library.borrow.dueDate") + record.dueDate)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)

                                HStack {
                                    Text(record.status)
                                        .font(.caption)
                                        .foregroundStyle(DSColor.secondary)

                                    Spacer()

                                    Text(record.renewable ? LocalizedStringKey("library.borrow.renewable") : LocalizedStringKey("library.borrow.notRenewable"))
                                        .font(.caption)
                                        .foregroundStyle(record.renewable ? DSColor.primary : DSColor.subtitle)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStringKey("library.myBorrow"))
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

                    infoRow(title: localizedString("library.renew.borrowDate"), value: record.borrowDate)
                    infoRow(title: localizedString("library.renew.dueDate"), value: record.dueDate)
                    infoRow(title: localizedString("library.renew.status"), value: record.status)
                    infoRow(title: localizedString("library.renew.token"), value: record.renewable ? localizedString("library.renew.tokenAcquired") : localizedString("library.borrow.notRenewable"))
                }

                DSCard {
                    Text(LocalizedStringKey("library.renew.instructions"))
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Text(LocalizedStringKey("library.renew.instructionsDetail"))
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(4)

                    DSButton(
                        title: localizedString("library.renew.button"),
                        icon: "arrow.clockwise",
                        isLoading: viewModel.submitState.isSubmitting,
                        isDisabled: !record.renewable
                    ) {
                        viewModel.clearSubmitState()
                        password = viewModel.borrowPassword
                        showPasswordSheet = true
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle(LocalizedStringKey("library.renew.detailTitle"))
        .sheet(isPresented: $showPasswordSheet, onDismiss: {
            password = ""
            viewModel.clearSubmitState()
        }) {
            PasswordInputSheet(
                title: localizedString("library.renew.sheetTitle"),
                message: localizedString("library.renew.sheetMessage"),
                placeholder: localizedString("library.borrow.passwordPlaceholder"),
                confirmTitle: localizedString("library.renew.confirmButton"),
                keyboardType: .default,
                isSubmitting: viewModel.submitState.isSubmitting,
                errorMessage: {
                    if case .failure(let message) = viewModel.submitState { return message }
                    return nil
                }(),
                password: $password,
                onCancel: {
                    viewModel.clearSubmitState()
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
        .alert(LocalizedStringKey("library.notice"), isPresented: Binding(
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
            Button(LocalizedStringKey("library.understood")) {
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
