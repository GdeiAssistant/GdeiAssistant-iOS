import SwiftUI

struct DataCenterView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        List {
            NavigationLink {
                ElectricityFeesView(viewModel: ElectricityFeesViewModel(repository: container.dataCenterRepository))
            } label: {
                Label(localizedString("dataCenter.electricQuery"), systemImage: "bolt.fill")
            }

            NavigationLink {
                YellowPageView(viewModel: YellowPageViewModel(repository: container.dataCenterRepository))
            } label: {
                Label(localizedString("dataCenter.yellowPage"), systemImage: "phone.fill")
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
                Picker(localizedString("dataCenter.year"), selection: $viewModel.query.year) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
                TextField(localizedString("dataCenter.name"), text: $viewModel.query.name)
                TextField(localizedString("dataCenter.studentId"), text: $viewModel.query.studentNumber)
                    .keyboardType(.numberPad)
                Button(localizedString("dataCenter.queryElec")) {
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
                Text(localizedString("dataCenter.queryCondition"))
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: localizedString("dataCenter.queryingElec"))
                }
            } else if let bill = viewModel.bill {
                Section {
                    row(localizedString("dataCenter.year"), String(bill.year))
                    row(localizedString("dataCenter.dorm"), "\(bill.buildingNumber) \(bill.roomNumber)")
                    row(localizedString("dataCenter.occupants"), bill.peopleNumber)
                    row(localizedString("dataCenter.college"), bill.department)
                    row(localizedString("dataCenter.usedElec"), bill.usedElectricAmount)
                    row(localizedString("dataCenter.freeElec"), bill.freeElectricAmount)
                    row(localizedString("dataCenter.chargedElec"), bill.feeBasedElectricAmount)
                    row(localizedString("dataCenter.elecPrice"), bill.electricPrice)
                    row(localizedString("dataCenter.totalFee"), bill.totalElectricBill)
                    row(localizedString("dataCenter.avgFee"), bill.averageElectricBill)
                } header: {
                    Text(localizedString("dataCenter.queryResult"))
                }
            }
        }
        .navigationTitle(localizedString("dataCenter.electricQuery"))
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
                DSLoadingView(text: localizedString("dataCenter.ypLoading"))
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
        .navigationTitle(localizedString("dataCenter.yellowPage"))
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
                infoRow(localizedString("dataCenter.department"), entry.section)
                if !entry.campus.isEmpty {
                    infoRow(localizedString("dataCenter.campus"), entry.campus)
                }
                if !entry.address.isEmpty {
                    infoRow(localizedString("dataCenter.address"), entry.address)
                }
            }

            if !entry.majorPhone.isEmpty || !entry.minorPhone.isEmpty {
                Section(localizedString("dataCenter.phone")) {
                    if !entry.majorPhone.isEmpty {
                        phoneActionRow(title: localizedString("dataCenter.mainPhone"), value: entry.majorPhone)
                    }
                    if !entry.minorPhone.isEmpty {
                        phoneActionRow(title: localizedString("dataCenter.backupPhone"), value: entry.minorPhone)
                    }
                }
            }

            if !entry.email.isEmpty || !entry.website.isEmpty {
                Section(localizedString("dataCenter.otherContact")) {
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
        .navigationTitle(localizedString("dataCenter.ypDetail"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(localizedString("dataCenter.done")) { dismiss() }
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
                Button(localizedString("dataCenter.call")) {
                    guard let url = URL(string: "tel:\(sanitizedPhone(value))") else { return }
                    openURL(url)
                }
                .buttonStyle(.bordered)

                Button(localizedString("dataCenter.sms")) {
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
