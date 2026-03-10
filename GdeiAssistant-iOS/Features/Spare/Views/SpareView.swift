import SwiftUI

struct SpareView: View {
    @StateObject private var viewModel: SpareViewModel

    init(viewModel: SpareViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("校区", selection: $viewModel.query.zone) {
                    ForEach(Array(SpareRemoteMapper.zoneTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Picker("课室类型", selection: $viewModel.query.type) {
                    ForEach(Array(SpareRemoteMapper.typeTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Stepper("开始节次：\(viewModel.query.startTime)", value: $viewModel.query.startTime, in: 1...20)
                Stepper("结束节次：\(viewModel.query.endTime)", value: $viewModel.query.endTime, in: viewModel.query.startTime...20)
                Stepper("星期：\(viewModel.query.minWeek + 1)", value: $viewModel.query.minWeek, in: 0...6)
                Picker("单双周", selection: $viewModel.query.weekType) {
                    ForEach(Array(SpareRemoteMapper.weekTypeTitles.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                Stepper("课节组：\(viewModel.query.classNumber)", value: $viewModel.query.classNumber, in: 1...10)
                Button("查询空教室") {
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
                Text("查询条件")
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: "正在查询空教室...")
                }
            } else if viewModel.items.isEmpty {
                Section {
                    DSEmptyStateView(icon: "building.2", title: "暂无空教室结果", message: "设置条件后开始查询")
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.roomName)
                                .font(.headline)
                            Text("\(item.zoneName) · \(item.roomType)")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Text("节次：\(item.sectionText)  座位：\(item.classSeating)")
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("查询结果")
                }
            }
        }
        .navigationTitle("空教室")
    }
}

#Preview {
    NavigationStack {
        SpareView(viewModel: SpareViewModel(repository: MockSpareRepository()))
    }
}
