import SwiftUI
import PhotosUI
import UIKit


struct MarketplaceProfileView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @State private var summary: MarketplacePersonalSummary?
    @State private var selectedTab: MarketplaceProfileTab = .doing
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingDetail: MarketplaceDetail?
    @State private var pendingStateChange: MarketplaceStateChangeContext?
    @State private var actionMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("marketplace.profileLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadData() }
                }
            } else if let summary {
                MarketplaceProfileSummaryView(
                    summary: summary,
                    selectedTab: $selectedTab,
                    actionMessage: actionMessage,
                    actionsProvider: actions(for:),
                    onOpen: { itemID in
                        Task { await openDetail(itemID) }
                    },
                    onAction: { action, item in
                        handleAction(action, item: item)
                    }
                )
                .refreshable {
                    await loadData()
                }
            }
        }
        .navigationTitle(localizedString("marketplace.profileCenter"))
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditMarketplaceView(
                    listViewModel: viewModel,
                    viewModel: EditMarketplaceViewModel(detail: detail)
                ) {
                    await loadData()
                }
            }
        }
        .confirmationDialog(localizedString("marketplace.confirmUpdateState"), isPresented: Binding(
            get: { pendingStateChange != nil },
            set: { if !$0 { pendingStateChange = nil } }
        )) {
            if let pendingStateChange {
                Button(pendingStateChange.buttonTitle, role: pendingStateChange.role) {
                    Task { await updateState(pendingStateChange) }
                }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        }
        .task {
            await loadData()
        }
    }

    private func items(for summary: MarketplacePersonalSummary) -> [MarketplaceItem] {
        switch selectedTab {
        case .doing:
            return summary.doing
        case .sold:
            return summary.sold
        case .off:
            return summary.off
        }
    }

    private func actions(for item: MarketplaceItem) -> [MarketplaceProfileAction] {
        switch selectedTab {
        case .doing:
            return [.edit, .offShelf, .sold]
        case .sold:
            return []
        case .off:
            return [.edit, .putBack]
        }
    }

    private func handleAction(_ action: MarketplaceProfileAction, item: MarketplaceItem) {
        switch action {
        case .edit:
            Task { await openDetail(item.id, forEditing: true) }
        case .offShelf:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .offShelf)
        case .sold:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .sold)
        case .putBack:
            pendingStateChange = MarketplaceStateChangeContext(itemID: item.id, state: .selling)
        }
    }

    private func openDetail(_ itemID: String, forEditing: Bool = false) async {
        do {
            let detail = try await viewModel.fetchDetail(itemID: itemID)
            if forEditing {
                editingDetail = detail
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.detailLoadFailed")
        }
    }

    private func updateState(_ context: MarketplaceStateChangeContext) async {
        defer { pendingStateChange = nil }
        do {
            try await viewModel.updateState(itemID: context.itemID, state: context.state)
            actionMessage = context.successMessage
            await loadData()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.actionFailed")
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            summary = try await viewModel.fetchMySummary()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.profileLoadFailed")
        }
    }
}

struct MarketplaceProfileSummaryView: View {
    let summary: MarketplacePersonalSummary
    @Binding var selectedTab: MarketplaceProfileTab
    let actionMessage: String?
    let actionsProvider: (MarketplaceItem) -> [MarketplaceProfileAction]
    let onOpen: (String) -> Void
    let onAction: (MarketplaceProfileAction, MarketplaceItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.md) {
                MarketplaceProfileHeaderView(summary: summary)
                MarketplaceProfileTabSelector(selectedTab: $selectedTab)

                if let actionMessage {
                    Label(actionMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(DSColor.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if currentItems.isEmpty {
                    DSEmptyStateView(icon: "bag", title: selectedTab.emptyTitle, message: selectedTab.emptyMessage)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(currentItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                DSRowDivider(leadingInset: 72 + DSSpacing.sm)
                            }
                            MarketplaceProfileItemCard(
                                item: item,
                                actions: actionsProvider(item),
                                onOpen: { onOpen(item.id) },
                                onAction: { action in
                                    onAction(action, item)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, DSSpacing.md)
                    .dsSurface()
                }
            }
            .padding(DSSpacing.md)
        }
        .dsScreenBackground()
    }

    private var currentItems: [MarketplaceItem] {
        switch selectedTab {
        case .doing:
            return summary.doing
        case .sold:
            return summary.sold
        case .off:
            return summary.off
        }
    }
}

struct MarketplaceProfileHeaderView: View {
    let summary: MarketplacePersonalSummary

    var body: some View {
        HStack(alignment: .center, spacing: DSSpacing.sm) {
            DSAvatarView(urlString: summary.avatarURL, size: 64)
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(summary.nickname)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DSColor.title)
                Text(summary.introduction)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsSurface()
    }
}

struct MarketplaceProfileTabSelector: View {
    @Binding var selectedTab: MarketplaceProfileTab

    var body: some View {
        Picker(selection: $selectedTab) {
            ForEach(MarketplaceProfileTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
    }
}

enum MarketplaceProfileTab: String, CaseIterable, Identifiable {
    case doing
    case sold
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doing:
            return localizedString("marketplace.tabSelling")
        case .sold:
            return localizedString("marketplace.tabSold")
        case .off:
            return localizedString("marketplace.tabOff")
        }
    }

    var emptyTitle: String {
        switch self {
        case .doing:
            return localizedString("marketplace.emptySelling")
        case .sold:
            return localizedString("marketplace.emptySold")
        case .off:
            return localizedString("marketplace.emptyOff")
        }
    }

    var emptyMessage: String {
        switch self {
        case .doing:
            return localizedString("marketplace.emptySellMsg")
        case .sold:
            return localizedString("marketplace.emptySoldMsg")
        case .off:
            return localizedString("marketplace.emptyOffMsg")
        }
    }
}

struct MarketplaceProfileItemCard: View {
    let item: MarketplaceItem
    let actions: [MarketplaceProfileAction]
    let onOpen: () -> Void
    let onAction: (MarketplaceProfileAction) -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Button(action: onOpen) {
                    HStack(alignment: .top, spacing: DSSpacing.sm) {
                        if item.previewImageURL != nil {
                            DSRemoteImageView(urlString: item.previewImageURL, cornerRadius: DSRadius.control)
                                .frame(width: 72, height: 72)
                        }

                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(DSColor.title)
                            Text("¥\(item.price, specifier: "%.2f")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DSColor.primary)
                            if let category = item.typeDisplayName(localeIdentifier: locale.identifier) {
                                Text(category)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            Text(item.postedAt)
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                if !actions.isEmpty {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(actions) { action in
                            if action.isPrimary {
                                Button(action.title, role: action.role) {
                                    onAction(action)
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button(action.title, role: action.role) {
                                    onAction(action)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .controlSize(.small)
                    .buttonBorderShape(.roundedRectangle(radius: DSRadius.control))
                    .tint(DSColor.primary)
                }
            }
        }
        .padding(.vertical, DSSpacing.sm)
    }
}

enum MarketplaceProfileAction: String, CaseIterable, Identifiable {
    case edit
    case offShelf
    case sold
    case putBack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .edit:
            return localizedString("marketplace.edit")
        case .offShelf:
            return localizedString("marketplace.offShelf")
        case .sold:
            return localizedString("marketplace.confirmSold")
        case .putBack:
            return localizedString("marketplace.putBack")
        }
    }

    var isPrimary: Bool {
        self == .sold || self == .putBack
    }

    var role: ButtonRole? {
        self == .offShelf ? .destructive : nil
    }
}

struct MarketplaceStateChangeContext: Identifiable {
    let itemID: String
    let state: MarketplaceItemState

    var id: String { "\(itemID)-\(state.rawValue)" }

    var buttonTitle: String {
        switch state {
        case .offShelf:
            return localizedString("marketplace.confirmOff")
        case .sold:
            return localizedString("marketplace.confirmSold")
        case .selling:
            return localizedString("marketplace.confirmSelling")
        case .unknown, .systemDeleted:
            return localizedString("marketplace.confirm")
        }
    }

    var role: ButtonRole? {
        state == .offShelf ? .destructive : nil
    }

    var successMessage: String {
        switch state {
        case .offShelf:
            return localizedString("marketplace.stateOffShelf")
        case .sold:
            return localizedString("marketplace.stateMarkedSold")
        case .selling:
            return localizedString("marketplace.stateRelist")
        case .unknown, .systemDeleted:
            return localizedString("marketplace.stateUpdated")
        }
    }
}
