import SwiftUI

struct DownloadDataView: View {
    @StateObject private var viewModel: DownloadDataViewModel

    init(viewModel: DownloadDataViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Label {
                        Text(viewModel.status.state.title)
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                    } icon: {
                        DSIconTile(systemName: iconName)
                    }

                    Text(viewModel.status.localizedMessage)
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)
                        .lineSpacing(3)
                }
                .padding(.vertical, DSSpacing.xxs)

                if let url = viewModel.status.downloadURL, !url.isEmpty {
                    Text(url)
                        .font(.footnote.monospaced())
                        .foregroundStyle(DSColor.primary)
                        .textSelection(.enabled)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                actionButton
                    .dsActionRow()
            }
        }
        .dsForm()
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
