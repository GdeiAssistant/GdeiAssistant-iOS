import SwiftUI

struct CollectionView: View {
    @StateObject private var viewModel: CollectionViewModel
    @State private var showBorrowSheet = false

    init(viewModel: CollectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    TextField(localizedString("collection.searchPlaceholder"), text: $viewModel.keyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(localizedString("collection.query")) {
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
                Text(localizedString("collection.catalogSearch"))
            }

            Section {
                Button {
                    showBorrowSheet = true
                } label: {
                    Label(localizedString("collection.myBorrow"), systemImage: "books.vertical")
                }
            } header: {
                Text(localizedString("collection.borrowService"))
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: localizedString("collection.searching"))
                }
            } else if viewModel.searchPage.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "magnifyingglass", title: localizedString("collection.noResult"), message: localizedString("collection.searchHint"))
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
                    Text(localizedString("collection.searchResult"))
                }
            }
        }
        .navigationTitle(localizedString("collection.library"))
        .overlay {
            if viewModel.isDetailLoading {
                DSLoadingView(text: localizedString("collection.detailLoading"))
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
                        SecureFormField(title: localizedString("collection.libPassword"), placeholder: localizedString("collection.enterPassword"), text: $viewModel.borrowPassword)
                        Button(viewModel.hasLoadedBorrowedBooks ? localizedString("collection.refreshBorrow") : localizedString("collection.queryBorrow")) {
                            Task { await viewModel.loadBorrowedBooks() }
                        }
                        .disabled(viewModel.isBorrowLoading)
                        Text(localizedString("collection.borrowHint"))
                            .font(.footnote)
                            .foregroundStyle(DSColor.subtitle)
                        if let borrowMessage = viewModel.borrowMessage {
                            Text(borrowMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.danger)
                        }
                    } header: {
                        Text(localizedString("collection.myBorrow"))
                    }

                    if viewModel.isBorrowLoading {
                        Section {
                            DSLoadingView(text: localizedString("collection.borrowLoading"))
                        }
                    } else if !viewModel.hasLoadedBorrowedBooks {
                        Section {
                            DSEmptyStateView(icon: "books.vertical", title: localizedString("collection.notQueried"), message: localizedString("collection.borrowEmptyHint"))
                        }
                    } else if viewModel.borrowedBooks.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "books.vertical", title: localizedString("collection.noBorrow"), message: localizedString("collection.noBorrowMsg"))
                        }
                    } else {
                        Section {
                            ForEach(viewModel.borrowedBooks) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.title)
                                            .font(.headline)
                                        Spacer()
                                        Button(localizedString("collection.renew")) {
                                            Task { await viewModel.renewBorrow(item: item) }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    Text(item.author)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                    Text("\(localizedString("collection.borrowLabel"))\(item.borrowDate)  \(localizedString("collection.returnLabel"))\(item.returnDate)  \(localizedString("collection.renewCount"))\(item.renewCount)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text(localizedString("collection.borrowList"))
                        }
                    }
                }
                .navigationTitle(localizedString("collection.myBorrow"))
                .alert(localizedString("collection.notice"), isPresented: Binding(
                    get: { viewModel.submitState.message != nil },
                    set: { if !$0 { viewModel.submitState = .idle } }
                )) {
                    Button(localizedString("collection.understood"), role: .cancel) {}
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
                    Text("\(localizedString("collection.subjectTheme"))\(detail.subjectTheme)")
                    Text("\(localizedString("collection.classification"))\(detail.classification)")
                } header: {
                    Text(localizedString("collection.bookInfo"))
                }

                Section {
                    ForEach(detail.distributions) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.location)
                                .font(.headline)
                            Text("\(localizedString("collection.callNumber"))\(item.callNumber)")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Text("\(item.barcode) · \(item.state)")
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }
                } header: {
                    Text(localizedString("collection.distribution"))
                }
            }
            .navigationTitle(localizedString("collection.detailTitle"))
        }
    }
}

#Preview {
    NavigationStack {
        CollectionView(viewModel: CollectionViewModel(repository: MockCollectionRepository()))
    }
}
