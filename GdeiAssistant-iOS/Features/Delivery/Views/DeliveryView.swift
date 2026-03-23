import SwiftUI

struct DeliveryView: View {
    @StateObject private var viewModel: DeliveryViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: DeliveryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.orders.isEmpty {
                DSLoadingView(text: localizedString("delivery.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.orders.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else {
                List {
                    if let actionMessage = viewModel.actionMessage {
                        Section {
                            Text(actionMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.primary)
                        }
                    }

                    if viewModel.orders.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "shippingbox.circle", title: localizedString("delivery.noOrders"), message: localizedString("delivery.noOrdersMessage"))
                        }
                    } else {
                        Section {
                            ForEach(viewModel.orders) { order in
                                NavigationLink {
                                    DeliveryDetailView(viewModel: viewModel, orderID: order.orderID, dismissAfterMutation: false)
                                } label: {
                                    DeliveryOrderRow(order: order)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text(localizedString("delivery.hall"))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle(localizedString("delivery.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(localizedString("delivery.mine")) {
                    MyDeliveryView(viewModel: viewModel)
                }
                NavigationLink(localizedString("delivery.publish")) {
                    PublishDeliveryView(viewModel: container.makePublishDeliveryViewModel(), listViewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct DeliveryOrderRow: View {
    let order: DeliveryOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedString("delivery.pickupDelivery"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                Spacer()
                Text("¥\(order.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(DSColor.primary)
            }

            routeRow(icon: "tray.and.arrow.down", title: localizedString("delivery.pickup"), value: "\(order.company) \(localizedString("delivery.pickupSuffix"))")
            routeRow(icon: "location", title: localizedString("delivery.deliver"), value: order.address)

            HStack {
                Text(order.orderTime)
                Spacer()
                Text(order.state.title)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusTint.opacity(0.12))
                    .foregroundStyle(statusTint)
                    .clipShape(Capsule())
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func routeRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(title == localizedString("delivery.pickup") ? DSColor.primary : DSColor.secondary)
                .clipShape(Circle())
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DSColor.title)
        }
    }

    private var statusTint: Color {
        switch order.state {
        case .pending:
            return DSColor.warning
        case .delivering:
            return DSColor.primary
        case .completed:
            return DSColor.secondary
        }
    }
}

struct DeliveryDetailView: View {
    @ObservedObject var viewModel: DeliveryViewModel
    let orderID: String
    let dismissAfterMutation: Bool
    let notificationTargetType: String?
    let notificationTargetSubID: String?
    let notificationID: String?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: DeliveryOrderDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var confirmFinish = false
    @State private var isSubmitting = false

    init(
        viewModel: DeliveryViewModel,
        orderID: String,
        dismissAfterMutation: Bool,
        notificationTargetType: String? = nil,
        notificationTargetSubID: String? = nil,
        notificationID: String? = nil
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.orderID = orderID
        self.dismissAfterMutation = dismissAfterMutation
        self.notificationTargetType = notificationTargetType
        self.notificationTargetSubID = notificationTargetSubID
        self.notificationID = notificationID
    }

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("delivery.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            if let notificationSummaryText {
                                Text(notificationSummaryText)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.primary)
                            }
                            Text(detail.order.state.title)
                                .font(.headline)
                                .foregroundStyle(statusTint(for: detail.order.state))
                            Text(detail.statusDescription)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text(localizedString("delivery.statusHeader"))
                    }

                    Section {
                        roleRow(detail.userRoleTitle)
                        infoRow(localizedString("delivery.publisherLabel"), detail.order.username)
                        infoRow(localizedString("delivery.pickupLocation"), "\(detail.order.company) \(localizedString("delivery.pickupSuffix"))")
                        infoRow(localizedString("delivery.deliveryAddress"), detail.order.address)
                        infoRow(localizedString("delivery.contactPhone"), detail.displayContactPhone)
                        if detail.hasMeaningfulPickupCode {
                            infoRow(localizedString("delivery.pickupCode"), detail.displayPickupCode)
                        }
                        infoRow(localizedString("delivery.reward"), String(format: "¥%.2f", detail.order.price))
                        infoRow(localizedString("delivery.publishTime"), detail.order.orderTime)
                        if !detail.order.remarks.isEmpty {
                            infoRow(localizedString("delivery.remarks"), detail.order.remarks)
                        }
                    } header: {
                        Text(localizedString("delivery.orderInfo"))
                    } footer: {
                        if !detail.canViewSensitiveInfo {
                            Text(localizedString("delivery.sensitiveInfoHidden"))
                        }
                    }

                    if let trade = detail.trade {
                        Section {
                            infoRow(localizedString("delivery.acceptor"), trade.username)
                            infoRow(localizedString("delivery.acceptTime"), trade.createTime)
                        } header: {
                            Text(localizedString("delivery.tradeInfo"))
                        }
                    }

                    Section {
                        if detail.canAccept {
                            Button(isSubmitting ? localizedString("delivery.accepting") : localizedString("delivery.acceptNow")) {
                                Task { await accept(detail.order.orderID) }
                            }
                            .disabled(isSubmitting)
                        }
                        if detail.canComplete, let trade = detail.trade {
                            Button(isSubmitting ? localizedString("delivery.processing") : localizedString("delivery.confirmComplete")) {
                                confirmFinish = true
                            }
                            .disabled(isSubmitting)
                            .confirmationDialog(localizedString("delivery.confirmCompleteDialog"), isPresented: $confirmFinish) {
                                Button(localizedString("delivery.confirmCompleteButton")) {
                                    Task { await finishTrade(trade.tradeID) }
                                }
                                Button(localizedString("common.cancel"), role: .cancel) {}
                            }
                        }
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text(localizedString("delivery.actions"))
                    } footer: {
                        if detail.canComplete {
                            Text(localizedString("delivery.completeFooter"))
                        } else {
                            Text(detail.order.state.descriptionText)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(localizedString("delivery.detailTitle"))
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(orderID: orderID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("delivery.detailLoadFailed")
        }
    }

    private func accept(_ orderID: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await viewModel.accept(orderID: orderID)
            resultMessage = localizedString("delivery.acceptSuccess")
            await loadDetail()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("delivery.acceptFailed")
        }
    }

    private func finishTrade(_ tradeID: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await viewModel.finishTrade(tradeID: tradeID)
            resultMessage = localizedString("delivery.orderCompleted")
            if dismissAfterMutation {
                dismiss()
            } else {
                await loadDetail()
            }
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("delivery.operationFailed")
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(DSColor.title)
        }
        .font(.subheadline)
    }

    private func roleRow(_ role: String) -> some View {
        HStack {
            Text(localizedString("delivery.myRole"))
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(role)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DSColor.primary.opacity(0.14))
                .foregroundStyle(DSColor.primary)
                .clipShape(Capsule())
        }
    }

    private func statusTint(for state: DeliveryOrderState) -> Color {
        switch state {
        case .pending:
            return DSColor.warning
        case .delivering:
            return DSColor.primary
        case .completed:
            return DSColor.secondary
        }
    }

    private var notificationSummaryText: String? {
        guard notificationID != nil else { return nil }

        switch normalizedNotificationTargetType {
        case "published":
            if let notificationTargetSubID {
                return String(format: localizedString("delivery.notificationAcceptedTrade"), notificationTargetSubID)
            }
            return localizedString("delivery.notificationAccepted")
        case "accepted":
            if let notificationTargetSubID {
                return String(format: localizedString("delivery.notificationCompletedTrade"), notificationTargetSubID)
            }
            return localizedString("delivery.notificationCompleted")
        default:
            return localizedString("delivery.notificationGeneric")
        }
    }

    private var normalizedNotificationTargetType: String? {
        RemoteMapperSupport.sanitizedText(notificationTargetType)
    }
}

private struct PublishDeliveryView: View {
    @StateObject private var viewModel: PublishDeliveryViewModel
    @ObservedObject var listViewModel: DeliveryViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var container: AppContainer

    init(viewModel: PublishDeliveryViewModel, listViewModel: DeliveryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.listViewModel = listViewModel
    }

    var body: some View {
        Form {
            Section {
                TextField(localizedString("delivery.pickupPlacePlaceholder"), text: $viewModel.pickupPlace)
                TextField(localizedString("delivery.pickupCodePlaceholder"), text: $viewModel.pickupNumber)
                TextField(localizedString("delivery.phonePlaceholder"), text: $viewModel.phone)
                    .keyboardType(.numberPad)
                TextField(localizedString("delivery.addressPlaceholder"), text: $viewModel.address)
                TextField(localizedString("delivery.remarksPlaceholder"), text: $viewModel.remarks, axis: .vertical)
                    .lineLimit(3...5)
                TextField(localizedString("delivery.rewardPlaceholder"), text: $viewModel.rewardText)
                    .keyboardType(.decimalPad)
            } header: {
                Text(localizedString("delivery.orderInfo"))
            } footer: {
                Text(localizedString("delivery.publishFooter"))
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle(localizedString("delivery.publishTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? localizedString("delivery.submitting") : localizedString("common.submit")) {
                    Task {
                        let success = await viewModel.submit()
                        if success {
                            await listViewModel.refresh()
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
    }
}

private struct MyDeliveryView: View {
    @ObservedObject var viewModel: DeliveryViewModel
    @State private var selectedTab: DeliveryMineTab = .published
    @State private var statusFilter: DeliveryMineStatusFilter = .all

    private var currentOrders: [DeliveryOrder] {
        let base: [DeliveryOrder]
        switch selectedTab {
        case .published:
            base = viewModel.mine.published
        case .accepted:
            base = viewModel.mine.accepted
        }
        switch statusFilter {
        case .all:
            return base
        case .pending:
            return base.filter { $0.state == .pending }
        case .delivering:
            return base.filter { $0.state == .delivering }
        case .completed:
            return base.filter { $0.state == .completed }
        }
    }

    var body: some View {
        List {
            Section {
                Picker(localizedString("delivery.myOrders"), selection: $selectedTab) {
                    ForEach(DeliveryMineTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    summaryCard(title: localizedString("delivery.publishedTab"), value: viewModel.mine.published.count, tint: DSColor.primary)
                    summaryCard(title: localizedString("delivery.acceptedTab"), value: viewModel.mine.accepted.count, tint: DSColor.secondary)
                }
            }

            Section {
                Picker(localizedString("delivery.statusFilter"), selection: $statusFilter) {
                    ForEach(DeliveryMineStatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let actionMessage = viewModel.actionMessage {
                Section {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.primary)
                }
            }

            if currentOrders.isEmpty {
                Section {
                    DSEmptyStateView(
                        icon: selectedTab == .published ? "square.and.arrow.up" : "shippingbox.circle",
                        title: selectedTab == .published ? localizedString("delivery.noPublishedOrders") : localizedString("delivery.noAcceptedOrders"),
                        message: emptyMessage
                    )
                }
            } else {
                Section {
                    ForEach(currentOrders) { order in
                        NavigationLink {
                            DeliveryDetailView(viewModel: viewModel, orderID: order.orderID, dismissAfterMutation: true)
                        } label: {
                            DeliveryOrderRow(order: order)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(selectedTab.title)
                }
            }
        }
        .navigationTitle(localizedString("delivery.myDelivery"))
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.refreshMine()
        }
    }

    private var emptyMessage: String {
        switch (selectedTab, statusFilter) {
        case (.published, .all):
            return localizedString("delivery.emptyPublished")
        case (.accepted, .all):
            return localizedString("delivery.emptyAccepted")
        default:
            return localizedString("delivery.emptyFiltered")
        }
    }

    private func summaryCard(title: String, value: Int, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(DSColor.title)
            Text(title)
                .font(.caption)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        DeliveryView(viewModel: DeliveryViewModel(repository: MockDeliveryRepository()))
            .environmentObject(AppContainer.preview)
    }
}
