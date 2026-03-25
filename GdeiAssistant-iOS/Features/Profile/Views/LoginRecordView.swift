import SwiftUI

struct LoginRecordView: View {
    @StateObject private var viewModel: LoginRecordViewModel

    init(viewModel: LoginRecordViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.records.isEmpty {
                DSLoadingView(text: localizedString("loginRecord.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.records.isEmpty {
                DSEmptyStateView(icon: "clock.arrow.circlepath", title: localizedString("loginRecord.emptyTitle"), message: localizedString("loginRecord.emptyMsg"))
            } else {
                List(viewModel.records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(record.timeText)
                                .font(.headline)
                            Spacer()
                            Text(record.statusText)
                                .font(.caption)
                                .foregroundStyle(DSColor.primary)
                        }
                        Text("\(record.area) · \(record.ip)")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(record.device)
                            .font(.caption)
                            .foregroundStyle(DSColor.subtitle)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(localizedString("loginRecord.title"))
        .task {
            await viewModel.load()
        }
    }
}
