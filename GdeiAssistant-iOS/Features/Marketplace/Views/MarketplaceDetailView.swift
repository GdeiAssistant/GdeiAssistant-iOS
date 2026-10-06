import SwiftUI
import PhotosUI
import UIKit


struct MarketplaceDetailView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    let itemID: String
    @EnvironmentObject private var container: AppContainer
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    @State private var detail: MarketplaceDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var isSubmitting = false
    @State private var editingDetail: MarketplaceDetail?
    @State private var confirmState: MarketplaceItemState?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("marketplace.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        if !detail.imageURLs.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DSSpacing.sm) {
                                    ForEach(detail.imageURLs, id: \.self) { imageURL in
                                        DSRemoteImageView(urlString: imageURL)
                                            .frame(width: 240, height: 180)
                                    }
                                }
                                .padding(.horizontal, DSSpacing.md)
                            }
                            .padding(.horizontal, -DSSpacing.md)
                        }

                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("¥\(detail.item.price, specifier: "%.2f")")
                                .font(.title.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(DSColor.primary)
                            Text(detail.item.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(DSColor.title)
                                .fixedSize(horizontal: false, vertical: true)
                            DSTag(text: detail.item.state.title)
                        }

                        DSGroupedSection {
                            Text(detail.description)
                                .font(.body)
                                .foregroundStyle(DSColor.title)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, DSSpacing.sm)
                                .accessibilityIdentifier("marketplace.detail.description")
                        }

                        DSGroupedSection {
                            HStack(spacing: DSSpacing.sm) {
                                SocialAvatarView(urlString: detail.item.sellerAvatarURL, size: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    if let authorId = detail.item.authorId {
                                        NavigationLink {
                                            SocialPublicProfileRoute(userID: authorId)
                                        } label: {
                                            Text(detail.sellerNickname ?? detail.item.sellerName)
                                                .font(.headline)
                                                .foregroundStyle(DSColor.primary)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Text(detail.sellerNickname ?? detail.item.sellerName)
                                            .font(.headline)
                                            .foregroundStyle(DSColor.title)
                                    }
                                    Text(sellerMetaText(detail))
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, DSSpacing.sm)

                            DSRowDivider()
                            infoRow(title: localizedString("marketplace.seller"), value: detail.item.sellerName)
                            DSRowDivider()
                            infoRow(title: localizedString("marketplace.status"), value: detail.item.state.title)
                            DSRowDivider()
                            infoRow(title: localizedString("marketplace.category"), value: detail.categoryDisplayName(localeIdentifier: locale.identifier))
                            DSRowDivider()
                            infoRow(title: localizedString("marketplace.location"), value: detail.item.location)
                            DSRowDivider()
                            infoRow(title: localizedString("marketplace.contactHint"), value: detail.contactHint)
                        }

                        if isOwnedByCurrentUser(detail) {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                if let resultMessage {
                                    Text(resultMessage)
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.primary)
                                }

                                if detail.item.state == .selling {
                                    Button {
                                        confirmState = .sold
                                    } label: {
                                        Text(isSubmitting ? localizedString("marketplace.processing") : localizedString("marketplace.markSold"))
                                            .font(.body.weight(.semibold))
                                            .frame(maxWidth: .infinity, minHeight: 36)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSubmitting)

                                    HStack(spacing: DSSpacing.sm) {
                                        Button {
                                            editingDetail = detail
                                        } label: {
                                            Text(localizedString("marketplace.editItemInfo"))
                                                .frame(maxWidth: .infinity, minHeight: 36)
                                        }
                                        .buttonStyle(.bordered)

                                        Button(role: .destructive) {
                                            confirmState = .offShelf
                                        } label: {
                                            Text(localizedString("marketplace.removeItem"))
                                                .frame(maxWidth: .infinity, minHeight: 36)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(isSubmitting)
                                    }
                                } else {
                                    Text(localizedString("marketplace.itemNotInHall"))
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            .buttonBorderShape(.roundedRectangle(radius: DSRadius.control))
                            .tint(DSColor.primary)
                        }
                    }
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.md)
                }
                .dsScreenBackground()
            }
        }
        .navigationTitle(localizedString("marketplace.detailTitle"))
        .confirmationDialog(localizedString("marketplace.confirmUpdateState"), isPresented: Binding(
            get: { confirmState != nil },
            set: { if !$0 { confirmState = nil } }
        )) {
            if let confirmState {
                Button(confirmState.title, role: confirmState == .offShelf ? .destructive : nil) {
                    Task { await updateState(confirmState) }
                }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        }
        .sheet(item: $editingDetail) { detail in
            NavigationStack {
                EditMarketplaceView(
                    listViewModel: viewModel,
                    viewModel: EditMarketplaceViewModel(detail: detail)
                ) {
                    await loadDetail()
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(itemID: itemID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.detailLoadFailed")
        }
    }

    private func isOwnedByCurrentUser(_ detail: MarketplaceDetail) -> Bool {
        detail.ownedByCurrentUser
    }

    private func updateState(_ state: MarketplaceItemState) async {
        isSubmitting = true
        defer {
            isSubmitting = false
            confirmState = nil
        }

        do {
            try await viewModel.updateState(itemID: itemID, state: state)
            resultMessage = localizedString("marketplace.itemStatusUpdated")
            dismiss()
        } catch {
            resultMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("marketplace.updateFailed")
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        DSValueRow(title: title, value: value)
    }

    private func sellerMetaText(_ detail: MarketplaceDetail) -> String {
        [detail.sellerCollege, detail.sellerMajor, detail.sellerGrade]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
}
