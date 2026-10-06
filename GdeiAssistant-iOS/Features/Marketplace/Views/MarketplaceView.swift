import SwiftUI
import PhotosUI
import UIKit


struct MarketplaceView: View {
    @StateObject private var viewModel: MarketplaceViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.locale) private var locale

    init(viewModel: MarketplaceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField(localizedString("marketplace.search"), text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await viewModel.search() } }
                    if !viewModel.searchQuery.isEmpty {
                        Button { Task { await viewModel.clearSearch() } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DSColor.subtitle)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)

                typeSelector
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if viewModel.isLoading && viewModel.items.isEmpty {
                Section {
                    DSLoadingView(text: localizedString("marketplace.loading"))
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "bag", title: localizedString("marketplace.emptyTitle"), message: localizedString("marketplace.emptyMessage"))
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            MarketplaceDetailView(viewModel: viewModel, itemID: item.id)
                        } label: {
                            HStack(alignment: .top, spacing: DSSpacing.sm) {
                                if item.previewImageURL != nil {
                                    DSRemoteImageView(urlString: item.previewImageURL, cornerRadius: DSRadius.control)
                                        .frame(width: 76, height: 76)
                                }

                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    HStack {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                        Spacer()
                                        Text("¥\(item.price, specifier: "%.2f")")
                                            .font(.headline)
                                            .monospacedDigit()
                                            .foregroundStyle(DSColor.primary)
                                    }

                                    if let category = item.typeDisplayName(localeIdentifier: locale.identifier) {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                    }
                                    Text(item.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)
                                        .lineLimit(2)

                                    HStack {
                                        if let authorId = item.authorId {
                                            NavigationLink {
                                                SocialPublicProfileRoute(userID: authorId)
                                            } label: {
                                                Text(item.sellerName)
                                                    .foregroundStyle(DSColor.primary)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            Text(item.sellerName)
                                        }
                                        Spacer()
                                        Text(item.location)
                                        Text(item.postedAt)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            .padding(.vertical, DSSpacing.xxs)
                        }
                        .accessibilityIdentifier("marketplace.item.\(item.id)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(AppDestination.marketplace.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    MarketplaceProfileView(viewModel: viewModel)
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel(localizedString("marketplace.mine"))

                NavigationLink {
                    PublishMarketplaceView(
                        listViewModel: viewModel,
                        publishViewModel: container.makePublishMarketplaceViewModel()
                    )
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel(localizedString("marketplace.publish"))
                .accessibilityIdentifier("marketplace.publishEntry")
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.sm) {
                filterChip(title: localizedString("marketplace.all"), isSelected: viewModel.selectedTypeID == nil) {
                    Task {
                        viewModel.selectedTypeID = nil
                        await viewModel.refresh()
                    }
                }

                ForEach(viewModel.typeOptions, id: \.id) { option in
                    filterChip(title: option.title, isSelected: viewModel.selectedTypeID == option.id) {
                        Task {
                            viewModel.selectedTypeID = option.id
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .padding(.vertical, DSSpacing.xxs)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? DSColor.onPrimary : DSColor.primary)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(isSelected ? DSColor.primary : DSColor.primarySoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
