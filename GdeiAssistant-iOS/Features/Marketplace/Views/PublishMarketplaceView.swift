import SwiftUI
import PhotosUI
import UIKit


struct PublishMarketplaceView: View {
    @ObservedObject var listViewModel: MarketplaceViewModel
    @StateObject private var publishViewModel: PublishMarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(
        listViewModel: MarketplaceViewModel,
        publishViewModel: PublishMarketplaceViewModel
    ) {
        self.listViewModel = listViewModel
        _publishViewModel = StateObject(wrappedValue: publishViewModel)
    }

    var body: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(publishViewModel.images) { image in
                            ZStack(alignment: .topTrailing) {
                                previewImageView(image)

                                Button {
                                    publishViewModel.removeImage(id: image.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, DSColor.danger)
                                }
                                .offset(x: 6, y: -6)
                            }
                        }

                        if publishViewModel.images.count < 4 {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 4 - publishViewModel.images.count,
                                matching: .images
                            ) {
                                VStack(spacing: DSSpacing.xs) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title3)
                                    Text(localizedString("marketplace.addImage"))
                                        .font(.caption)
                                }
                                .frame(width: 92, height: 92)
                                .background(DSColor.fieldBackground)
                                .clipShape(DSRadius.controlShape)
                            }
                        }
                    }
                    .padding(.vertical, DSSpacing.xxs)
                }

                Text(localizedString("marketplace.imageHint"))
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text(localizedString("marketplace.itemImages"))
                    .accessibilityIdentifier("marketplace.publish.images")
            }

            Section {
                TextField(localizedString("marketplace.itemName"), text: $publishViewModel.title)
                TextField(localizedString("marketplace.price"), text: $publishViewModel.priceText)
                    .keyboardType(.decimalPad)
                Picker(localizedString("marketplace.itemCategory"), selection: $publishViewModel.selectedTypeID) {
                    ForEach(Array(publishViewModel.typeOptions.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index)
                    }
                }
                TextField(localizedString("marketplace.itemDescription"), text: $publishViewModel.descriptionText, axis: .vertical)
                    .lineLimit(4...6)
                TextField(localizedString("marketplace.tradeLocation"), text: $publishViewModel.location)
                TextField(localizedString("marketplace.tags"), text: $publishViewModel.tagsText)
            } header: {
                Text(localizedString("marketplace.itemInfo"))
            }

            Section {
                TextField(localizedString("marketplace.qq"), text: $publishViewModel.qq)
                    .keyboardType(.numberPad)
                TextField(localizedString("marketplace.phoneOptional"), text: $publishViewModel.phone)
                    .keyboardType(.numberPad)
            } header: {
                Text(localizedString("marketplace.contact"))
            }

            if let failureMessage = publishViewModel.failureMessage {
                Section {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .dsListBackground()
        .navigationTitle(localizedString("marketplace.publishTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if publishViewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text(localizedString("marketplace.submit"))
                    }
                }
                .accessibilityIdentifier("marketplace.publish.submit")
                .disabled(publishViewModel.submitState.isSubmitting || !publishViewModel.isFormValid)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task { await loadSelectedImages(from: newItems) }
        }
        .alert(localizedString("marketplace.notice"), isPresented: Binding(
            get: {
                if case .success = publishViewModel.submitState {
                    return true
                }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    publishViewModel.submitState = .idle
                }
            }
        )) {
            Button(localizedString("marketplace.understood")) {
                publishViewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(publishViewModel.submitState.message ?? "")
        }
    }

    private func publish() async {
        guard let draft = publishViewModel.buildDraft() else { return }

        publishViewModel.submitState = .submitting

        do {
            try await listViewModel.publish(draft: draft)
            publishViewModel.submitState = .success(localizedString("marketplace.publishSuccess"))
        } catch {
            publishViewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.publishFailed"))
        }
    }

    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for item in items {
            guard publishViewModel.images.count < 4 else { break }
            guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { continue }

            let contentType = item.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let image = UploadImageAsset(
                fileName: "market-\(UUID().uuidString).\(fileExtension)",
                mimeType: mimeType,
                data: data
            )
            publishViewModel.addImage(image)
        }

        selectedPhotoItems = []
    }

    private func previewImageView(_ image: UploadImageAsset) -> some View {
        Group {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(DSColor.fieldBackground)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DSColor.subtitle)
                    }
            }
        }
        .frame(width: 92, height: 92)
        .background(DSColor.fieldBackground)
        .clipShape(DSRadius.controlShape)
    }
}
