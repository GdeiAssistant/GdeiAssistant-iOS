import SwiftUI

struct DataCenterView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        List {
            NavigationLink {
                ElectricityFeesView(viewModel: ElectricityFeesViewModel(repository: container.dataCenterRepository))
            } label: {
                Label("电费查询", systemImage: "bolt.fill")
            }

            NavigationLink {
                YellowPageView(viewModel: YellowPageViewModel(repository: container.dataCenterRepository))
            } label: {
                Label("黄页查询", systemImage: "phone.fill")
            }
        }
        .navigationTitle(AppDestination.dataCenter.title)
    }
}

struct ElectricityFeesView: View {
    @StateObject private var viewModel: ElectricityFeesViewModel

    init(viewModel: ElectricityFeesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("年份", selection: $viewModel.query.year) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
                TextField("姓名", text: $viewModel.query.name)
                TextField("学号", text: $viewModel.query.studentNumber)
                    .keyboardType(.numberPad)
                Button("查询电费") {
                    Task { await viewModel.submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            } header: {
                Text("查询条件")
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: "正在查询电费...")
                }
            } else if let bill = viewModel.bill {
                Section {
                    row("年份", String(bill.year))
                    row("宿舍", "\(bill.buildingNumber) \(bill.roomNumber)")
                    row("入住人数", bill.peopleNumber)
                    row("学院", bill.department)
                    row("用电数额", bill.usedElectricAmount)
                    row("免费电额", bill.freeElectricAmount)
                    row("计费电数", bill.feeBasedElectricAmount)
                    row("电价", bill.electricPrice)
                    row("总电费", bill.totalElectricBill)
                    row("平均电费", bill.averageElectricBill)
                } header: {
                    Text("查询结果")
                }
            }
        }
        .navigationTitle("电费查询")
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(DSColor.subtitle)
        }
    }
}

struct YellowPageView: View {
    @StateObject private var viewModel: YellowPageViewModel
    @Environment(\.openURL) private var openURL
    @State private var selectedEntry: YellowPageEntry?

    init(viewModel: YellowPageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.categories.isEmpty {
                DSLoadingView(text: "正在加载校园黄页...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.categories.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            } else {
                List(viewModel.categories) { category in
                    Section {
                        ForEach(category.items) { item in
                            Button {
                                selectedEntry = item
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.section)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                        if !item.campus.isEmpty {
                                            Text(item.campus)
                                                .font(.caption)
                                                .foregroundStyle(DSColor.subtitle)
                                        }
                                    }
                                    Spacer()
                                    if !item.majorPhone.isEmpty {
                                        Text(item.majorPhone)
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text(category.name)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("黄页查询")
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                YellowPageEntryDetailView(entry: entry)
            }
        }
    }
}

private struct YellowPageEntryDetailView: View {
    let entry: YellowPageEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                infoRow("部门单位", entry.section)
                if !entry.campus.isEmpty {
                    infoRow("校区", entry.campus)
                }
                if !entry.address.isEmpty {
                    infoRow("地址", entry.address)
                }
            }

            if !entry.majorPhone.isEmpty || !entry.minorPhone.isEmpty {
                Section("电话") {
                    if !entry.majorPhone.isEmpty {
                        phoneActionRow(title: "主要电话", value: entry.majorPhone)
                    }
                    if !entry.minorPhone.isEmpty {
                        phoneActionRow(title: "备用电话", value: entry.minorPhone)
                    }
                }
            }

            if !entry.email.isEmpty || !entry.website.isEmpty {
                Section("其他联系方式") {
                    if !entry.email.isEmpty {
                        Button {
                            if let url = URL(string: "mailto:\(entry.email)") {
                                openURL(url)
                            }
                        } label: {
                            Label(entry.email, systemImage: "envelope")
                        }
                    }
                    if !entry.website.isEmpty {
                        Button {
                            guard let url = normalizedWebsiteURL(entry.website) else { return }
                            openURL(url)
                        } label: {
                            Label(entry.website, systemImage: "globe")
                        }
                    }
                }
            }
        }
        .navigationTitle("黄页详情")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func phoneActionRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title)：\(value)")
                .font(.subheadline)
                .foregroundStyle(DSColor.title)

            HStack(spacing: 10) {
                Button("打电话") {
                    guard let url = URL(string: "tel:\(sanitizedPhone(value))") else { return }
                    openURL(url)
                }
                .buttonStyle(.bordered)

                Button("发短信") {
                    guard let url = URL(string: "sms:\(sanitizedPhone(value))") else { return }
                    openURL(url)
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }

    private func sanitizedPhone(_ value: String) -> String {
        value.filter { $0.isNumber || $0 == "+" }
    }

    private func normalizedWebsiteURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

#Preview {
    NavigationStack {
        DataCenterView()
            .environmentObject(AppContainer.preview)
    }
}
