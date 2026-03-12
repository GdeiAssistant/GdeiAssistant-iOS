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
                DSLoadingView(text: "正在加载跑腿订单...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.orders.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else {
                List {
                    Section {
                        Picker("状态", selection: $viewModel.selectedFilter) {
                            ForEach(DeliveryOrderFilter.allCases) { filter in
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

                    if viewModel.filteredOrders.isEmpty {
                        Section {
                            DSEmptyStateView(icon: "shippingbox.circle", title: "暂无订单", message: "当前筛选下没有可展示的订单")
                        }
                    } else {
                        Section {
                            ForEach(viewModel.filteredOrders) { order in
                                NavigationLink {
                                    DeliveryDetailView(viewModel: viewModel, orderID: order.orderID, dismissAfterMutation: false)
                                } label: {
                                    DeliveryOrderRow(order: order)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("跑腿大厅")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("全民快递")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink("我的") {
                    MyDeliveryView(viewModel: viewModel)
                }
                NavigationLink("发布") {
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
                Text("代取快递")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                Spacer()
                Text("¥\(order.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(DSColor.primary)
            }

            routeRow(icon: "tray.and.arrow.down", title: "取", value: "\(order.company) 取件")
            routeRow(icon: "location", title: "送", value: order.address)

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
                .background(title == "取" ? DSColor.primary : DSColor.secondary)
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
                DSLoadingView(text: "正在加载任务详情...")
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
                        Text("状态")
                    }

                    Section {
                        roleRow(detail.userRoleTitle)
                        infoRow("发布者", detail.order.username)
                        infoRow("取件地点", "\(detail.order.company) 取件")
                        infoRow("送达地址", detail.order.address)
                        infoRow("联系电话", detail.displayContactPhone)
                        if detail.hasMeaningfulPickupCode {
                            infoRow("取件码", detail.displayPickupCode)
                        }
                        infoRow("赏金", String(format: "¥%.2f", detail.order.price))
                        infoRow("发布时间", detail.order.orderTime)
                        if !detail.order.remarks.isEmpty {
                            infoRow("备注", detail.order.remarks)
                        }
                    } header: {
                        Text("订单信息")
                    } footer: {
                        if !detail.canViewSensitiveInfo {
                            Text("为保护发布者信息，完整联系方式会在接单后展示。")
                        }
                    }

                    if let trade = detail.trade {
                        Section {
                            infoRow("接单者", trade.username)
                            infoRow("接单时间", trade.createTime)
                        } header: {
                            Text("交易信息")
                        }
                    }

                    Section {
                        if detail.canAccept {
                            Button(isSubmitting ? "接单中..." : "立即抢单") {
                                Task { await accept(detail.order.orderID) }
                            }
                            .disabled(isSubmitting)
                        }
                        if detail.canComplete, let trade = detail.trade {
                            Button(isSubmitting ? "处理中..." : "确认订单完成") {
                                confirmFinish = true
                            }
                            .disabled(isSubmitting)
                            .confirmationDialog("确认订单已经完成交付？", isPresented: $confirmFinish) {
                                Button("确认订单完成") {
                                    Task { await finishTrade(trade.tradeID) }
                                }
                                Button("取消", role: .cancel) {}
                            }
                        }
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    } header: {
                        Text("操作")
                    } footer: {
                        if detail.canComplete {
                            Text("确认订单完成后，该订单会切换到已完成状态。")
                        } else {
                            Text(detail.order.state.descriptionText)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("任务详情")
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "详情加载失败"
        }
    }

    private func accept(_ orderID: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await viewModel.accept(orderID: orderID)
            resultMessage = "接单成功"
            await loadDetail()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "接单失败"
        }
    }

    private func finishTrade(_ tradeID: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await viewModel.finishTrade(tradeID: tradeID)
            resultMessage = "订单已完成"
            if dismissAfterMutation {
                dismiss()
            } else {
                await loadDetail()
            }
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "操作失败"
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
            Text("我的角色")
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
                return "来自互动消息：订单已被接单，交易号 \(notificationTargetSubID)"
            }
            return "来自互动消息：订单已被接单"
        case "accepted":
            if let notificationTargetSubID {
                return "来自互动消息：订单已完成，交易号 \(notificationTargetSubID)"
            }
            return "来自互动消息：订单已完成"
        default:
            return "来自互动消息"
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
                TextField("取件地点", text: $viewModel.pickupPlace)
                TextField("取件码 / 凭证（选填）", text: $viewModel.pickupNumber)
                TextField("联系电话", text: $viewModel.phone)
                    .keyboardType(.numberPad)
                TextField("送达地址", text: $viewModel.address)
                TextField("备注（选填）", text: $viewModel.remarks, axis: .vertical)
                    .lineLimit(3...5)
                TextField("跑腿费", text: $viewModel.rewardText)
                    .keyboardType(.decimalPad)
            } header: {
                Text("订单信息")
            } footer: {
                Text("与 Web 当前提交流程一致，取件码或凭证可不填写；未填写时会按前端默认值提交。")
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle("发布全民快递")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? "提交中..." : "提交") {
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
                Picker("我的订单", selection: $selectedTab) {
                    ForEach(DeliveryMineTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    summaryCard(title: "发布", value: viewModel.mine.published.count, tint: DSColor.primary)
                    summaryCard(title: "接单", value: viewModel.mine.accepted.count, tint: DSColor.secondary)
                }
            }

            Section {
                Picker("状态筛选", selection: $statusFilter) {
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
                        title: selectedTab == .published ? "暂无我发布的订单" : "暂无我接的订单",
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
        .navigationTitle("我的跑腿")
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
            return "去发布一个新的跑腿任务"
        case (.accepted, .all):
            return "去大厅看看有没有可接的单"
        default:
            return "当前状态下没有匹配的订单"
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
