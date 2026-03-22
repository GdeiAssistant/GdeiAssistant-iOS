import SwiftUI

struct SpareView: View {
    @StateObject private var viewModel: SpareViewModel

    init(viewModel: SpareViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker(LocalizedStringKey("spare.campus"), selection: $viewModel.query.zone) {
                    ForEach(Array(SpareRemoteMapper.zoneTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Picker(LocalizedStringKey("spare.roomType"), selection: $viewModel.query.type) {
                    ForEach(Array(SpareRemoteMapper.typeTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Stepper(String(format: localizedString("spare.startSection"), viewModel.query.startTime), value: $viewModel.query.startTime, in: 1...20)
                Stepper(String(format: localizedString("spare.endSection"), viewModel.query.endTime), value: $viewModel.query.endTime, in: viewModel.query.startTime...20)
                Stepper(String(format: localizedString("spare.weekday"), viewModel.query.minWeek + 1), value: $viewModel.query.minWeek, in: 0...6)
                Picker(LocalizedStringKey("spare.weekType"), selection: $viewModel.query.weekType) {
                    ForEach(Array(SpareRemoteMapper.weekTypeTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Stepper(String(format: localizedString("spare.classGroup"), viewModel.query.classNumber), value: $viewModel.query.classNumber, in: 1...10)
                Button(localizedString("spare.search")) {
                    Task { await viewModel.submitQuery() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            } header: {
                Text(LocalizedStringKey("spare.queryConditions"))
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: localizedString("spare.searching"))
                }
            } else if viewModel.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "building.2", title: localizedString("spare.emptyTitle"), message: localizedString("spare.emptyMessage"))
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.roomName)
                                .font(.headline)
                            Text("\(item.zoneName) \u{00B7} \(item.roomType)")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Text(String(format: localizedString("spare.sectionSeating"), item.sectionText, item.classSeating))
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(LocalizedStringKey("spare.results"))
                }
            }
        }
        .navigationTitle(localizedString("spare.title"))
    }
}

#Preview {
    NavigationStack {
        SpareView(viewModel: SpareViewModel(repository: MockSpareRepository()))
    }
}
