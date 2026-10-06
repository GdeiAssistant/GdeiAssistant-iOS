import SwiftUI
import PhotosUI
import UIKit


struct EditMarketplaceView: View {
    @ObservedObject var listViewModel: MarketplaceViewModel
    @StateObject private var viewModel: EditMarketplaceViewModel
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        listViewModel: MarketplaceViewModel,
        viewModel: EditMarketplaceViewModel,
        onSaved: @escaping () async -> Void
    ) {
        self.listViewModel = listViewModel
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                TextField(localizedString("marketplace.itemName"), text: $viewModel.title)
                TextField(localizedString("marketplace.price"), text: $viewModel.priceText)
                    .keyboardType(.decimalPad)
                Picker(localizedString("marketplace.itemCategory"), selection: $viewModel.selectedTypeID) {
                    ForEach(Array(viewModel.typeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                TextField(localizedString("marketplace.itemDescription"), text: $viewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField(localizedString("marketplace.tradeLocation"), text: $viewModel.location)
            } header: {
                Text(localizedString("marketplace.itemInfo"))
            }

            Section {
                TextField(localizedString("marketplace.qq"), text: $viewModel.qq)
                    .keyboardType(.numberPad)
                TextField(localizedString("marketplace.phoneOptional"), text: $viewModel.phone)
                    .keyboardType(.numberPad)
            } header: {
                Text(localizedString("marketplace.contact"))
            }

            if let failureMessage = viewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .dsListBackground()
        .navigationTitle(localizedString("marketplace.editTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localizedString("common.cancel")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.submitState.isSubmitting ? localizedString("marketplace.saving") : localizedString("marketplace.save")) {
                    Task { await submit() }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
    }

    private func submit() async {
        guard let draft = viewModel.buildDraft() else { return }
        viewModel.submitState = .submitting

        do {
            try await listViewModel.update(itemID: viewModel.itemID, draft: draft)
            viewModel.submitState = .success(localizedString("marketplace.itemUpdated"))
            await onSaved()
            dismiss()
        } catch {
            viewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.saveFailed"))
        }
    }
}

#Preview {
    let container = AppContainer.preview
    return NavigationStack {
        MarketplaceView(viewModel: MarketplaceViewModel(repository: MockMarketplaceRepository()))
            .environmentObject(container)
    }
}
