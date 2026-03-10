import SwiftUI

struct LoginRecordView: View {
    @StateObject private var viewModel: LoginRecordViewModel

    init(viewModel: LoginRecordViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.records.isEmpty {
                DSLoadingView(text: "正在加载登录记录...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.records.isEmpty {
                DSEmptyStateView(icon: "clock.arrow.circlepath", title: "暂无登录记录", message: "近期没有可展示的登录记录")
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
        .navigationTitle("登录记录")
        .task {
            await viewModel.load()
        }
    }
}
