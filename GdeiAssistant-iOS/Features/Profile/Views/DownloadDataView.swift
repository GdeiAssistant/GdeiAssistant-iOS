import SwiftUI

struct DownloadDataView: View {
    @StateObject private var viewModel: DownloadDataViewModel

    init(viewModel: DownloadDataViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    Label(viewModel.status.state.title, systemImage: iconName)
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Text(viewModel.status.localizedMessage)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(4)

                    if let url = viewModel.status.downloadURL, !url.isEmpty {
                        Text(url)
                            .font(.footnote)
                            .foregroundStyle(DSColor.primary)
                            .textSelection(.enabled)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    DSErrorStateView(message: errorMessage) {}
                }

                actionButton
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle(localizedString("downloadData.title"))
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.status.state {
        case .idle:
            DSButton(title: localizedString("downloadData.startExport"), icon: "archivebox", isLoading: viewModel.isLoading) {
                Task { await viewModel.startExport() }
            }
        case .exporting:
            DSButton(title: localizedString("downloadData.refreshStatus"), icon: "arrow.clockwise", variant: .secondary, isLoading: viewModel.isLoading) {
                Task { await viewModel.load() }
            }
        case .exported:
            DSButton(title: localizedString("downloadData.getURL"), icon: "arrow.down.circle", isLoading: viewModel.isLoading) {
                Task { await viewModel.fetchDownloadURL() }
            }
        }
    }

    private var iconName: String {
        switch viewModel.status.state {
        case .idle:
            return "tray"
        case .exporting:
            return "hourglass"
        case .exported:
            return "checkmark.circle"
        }
    }
}
