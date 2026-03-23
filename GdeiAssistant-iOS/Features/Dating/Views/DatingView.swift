import SwiftUI
import PhotosUI
import UIKit

struct DatingView: View {
    @StateObject private var viewModel: DatingHallViewModel
    @EnvironmentObject private var container: AppContainer

    init(viewModel: DatingHallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker(localizedString("dating.areaFilter"), selection: areaBinding) {
                    ForEach(DatingArea.allCases) { area in
                        Text(area.title).tag(area)
                    }
                }
                .pickerStyle(.segmented)
            }

            if viewModel.isLoading && viewModel.profiles.isEmpty {
                Section {
                    DSLoadingView(text: localizedString("dating.loading"))
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty {
                Section {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else if viewModel.profiles.isEmpty {
                Section {
                    DSEmptyStateView(icon: "person.3", title: localizedString("dating.noProfiles"), message: localizedString("dating.noProfilesMessage"))
                }
            } else {
                Section {
                    ForEach(viewModel.profiles) { profile in
                        NavigationLink {
                            DatingDetailView(viewModel: viewModel, profileID: profile.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                DSRemoteImageView(urlString: profile.imageURL, fallbackSystemImage: "person.crop.rectangle")
                                    .frame(width: 96, height: 120)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(profile.nickname)
                                        .font(.headline)
                                        .foregroundStyle(DSColor.title)

                                    Text(profile.headline)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.subtitle)

                                    Text(String(format: localizedString("dating.from"), profile.hometown))
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)

                                    Text(profile.bio)
                                        .font(.subheadline)
                                        .foregroundStyle(DSColor.title)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(localizedString("dating.title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(localizedString("dating.interactionCenter")) {
                    DatingCenterView(viewModel: container.makeDatingCenterViewModel())
                }

                NavigationLink(localizedString("dating.publish")) {
                    PublishDatingView(
                        listViewModel: viewModel,
                        viewModel: container.makePublishDatingViewModel()
                    )
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var areaBinding: Binding<DatingArea> {
        Binding(
            get: { viewModel.selectedArea },
            set: { newValue in
                Task { await viewModel.updateArea(newValue) }
            }
        )
    }
}

struct DatingCenterView: View {
    @StateObject private var viewModel: DatingCenterViewModel

    init(viewModel: DatingCenterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        DatingCenterContent(viewModel: viewModel, navigationTitle: localizedString("dating.interactionCenter"))
    }
}

private struct DatingCenterContent: View {
    @ObservedObject var viewModel: DatingCenterViewModel
    let navigationTitle: String

    @State private var confirmHideID: String?

    var body: some View {
        List {
            Section {
                Picker(localizedString("dating.interactionCenter"), selection: $viewModel.selectedTab) {
                    ForEach(DatingCenterTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedTab) { _, _ in
                    Task { await viewModel.loadData() }
                }
            }

            if let actionMessage = viewModel.actionMessage {
                Section {
                    Text(actionMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.primary)
                }
            }

            contentSection
        }
        .navigationTitle(navigationTitle)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
        .confirmationDialog(
            localizedString("dating.confirmHide"),
            isPresented: Binding(
                get: { confirmHideID != nil },
                set: { if !$0 { confirmHideID = nil } }
            )
        ) {
            Button(localizedString("dating.confirmHideButton"), role: .destructive) {
                guard let confirmHideID else { return }
                Task { await viewModel.hideProfile(id: confirmHideID) }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.selectedTab {
        case .received:
            if viewModel.isLoading && viewModel.receivedItems.isEmpty {
                Section { DSLoadingView(text: localizedString("dating.loadingGeneric")) }
            } else if viewModel.receivedItems.isEmpty {
                Section { DSEmptyStateView(icon: "tray", title: localizedString("dating.noReceived"), message: localizedString("dating.noReceivedMessage")) }
            } else {
                Section {
                    ForEach(viewModel.receivedItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 10) {
                                    DSAvatarView(urlString: item.avatarURL, size: 40)
                                    Text(item.senderName)
                                        .font(.headline)
                                }
                                Spacer()
                                Text(item.time)
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                            Text(item.content)
                                .font(.subheadline)
                            if item.status == .pending {
                                HStack {
                                    Button(localizedString("dating.approve")) {
                                        Task { await viewModel.updatePickState(id: item.id, state: .accepted) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button(localizedString("dating.reject")) {
                                        Task { await viewModel.updatePickState(id: item.id, state: .rejected) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                Text(item.status.title)
                                    .font(.caption)
                                    .foregroundStyle(item.status == .accepted ? DSColor.primary : DSColor.danger)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(localizedString("dating.receivedHeader"))
                }
            }
        case .sent:
            if viewModel.isLoading && viewModel.sentItems.isEmpty {
                Section { DSLoadingView(text: localizedString("dating.loadingGeneric")) }
            } else if viewModel.sentItems.isEmpty {
                Section { DSEmptyStateView(icon: "paperplane", title: localizedString("dating.noSent"), message: localizedString("dating.noSentMessage")) }
            } else {
                Section {
                    ForEach(viewModel.sentItems) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 10) {
                                    DSAvatarView(urlString: item.targetAvatarURL, size: 40)
                                    Text(item.targetName)
                                        .font(.headline)
                                }
                                Spacer()
                                Text(item.status.title)
                                    .font(.caption)
                                    .foregroundStyle(item.status == .accepted ? DSColor.primary : DSColor.subtitle)
                            }
                            Text(item.content)
                                .font(.subheadline)
                            if item.status == .accepted {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let qq = item.targetQq, !qq.isEmpty {
                                        Text(String(format: localizedString("dating.qqLabel"), qq))
                                    }
                                    if let wechat = item.targetWechat, !wechat.isEmpty {
                                        Text(String(format: localizedString("dating.wechatLabel"), wechat))
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(localizedString("dating.sentHeader"))
                }
            }
        case .posts:
            if viewModel.isLoading && viewModel.myPosts.isEmpty {
                Section { DSLoadingView(text: localizedString("dating.loadingGeneric")) }
            } else if viewModel.myPosts.isEmpty {
                Section { DSEmptyStateView(icon: "person.crop.square", title: localizedString("dating.noPosts"), message: localizedString("dating.noPostsMessage")) }
            } else {
                Section {
                    ForEach(viewModel.myPosts) { item in
                        HStack {
                            HStack(spacing: 10) {
                                DSAvatarView(urlString: item.imageURL, size: 40)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("\(item.grade) · \(item.faculty) · \(String(format: localizedString("dating.from"), item.hometown))")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                    Text(item.publishTime)
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }
                            Spacer()
                            Button(localizedString("dating.hideButton"), role: .destructive) {
                                confirmHideID = item.id
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(localizedString("dating.myPostsHeader"))
                }
            }
        }
    }
}

private struct DatingDetailView: View {
    @ObservedObject var viewModel: DatingHallViewModel
    let profileID: String

    @State private var detail: DatingProfileDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var pickContent = ""
    @State private var isSubmittingPick = false
    @State private var actionMessage: String?

    var body: some View {
        Group {
            if isLoading {
                DSLoadingView(text: localizedString("dating.detailLoading"))
            } else if let errorMessage {
                DSErrorStateView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                List {
                    Section {
                        HStack(alignment: .top, spacing: 16) {
                            DSRemoteImageView(urlString: detail.profile.imageURL, fallbackSystemImage: "person.crop.rectangle")
                                .frame(width: 120, height: 160)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(detail.profile.nickname)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(DSColor.title)
                                Text(detail.profile.headline)
                                    .font(.subheadline)
                                    .foregroundStyle(DSColor.subtitle)
                                Text(String(format: localizedString("dating.from"), detail.profile.hometown))
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)
                                Text(detail.profile.bio)
                                    .font(.body)
                                    .foregroundStyle(DSColor.title)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section(localizedString("dating.contactSection")) {
                        if detail.profile.isContactVisible {
                            if let qq = detail.profile.qq, !qq.isEmpty {
                                Text(String(format: localizedString("dating.qqLabel"), qq))
                            }
                            if let wechat = detail.profile.wechat, !wechat.isEmpty {
                                Text(String(format: localizedString("dating.wechatLabel"), wechat))
                            }
                            if (detail.profile.qq ?? "").isEmpty && (detail.profile.wechat ?? "").isEmpty {
                                Text(localizedString("dating.noContact"))
                                    .font(.footnote)
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        } else {
                            Text(localizedString("dating.contactHidden"))
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        }
                    }

                    Section(localizedString("dating.pickSection")) {
                        if detail.isPickNotAvailable && !detail.profile.isContactVisible {
                            Text(localizedString("dating.alreadyPicked"))
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        } else if detail.profile.isContactVisible {
                            Text(localizedString("dating.mutualConfirmed"))
                                .font(.footnote)
                                .foregroundStyle(DSColor.subtitle)
                        } else {
                            TextField(localizedString("dating.pickPlaceholder"), text: $pickContent, axis: .vertical)
                                .lineLimit(3...5)

                            Button {
                                Task { await submitPick() }
                            } label: {
                                if isSubmittingPick {
                                    ProgressView()
                                } else {
                                    Text(localizedString("dating.sendRequest"))
                                }
                            }
                            .disabled(isSubmittingPick || pickContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }

                    if let actionMessage {
                        Section {
                            Text(actionMessage)
                                .font(.footnote)
                                .foregroundStyle(DSColor.primary)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadDetail()
                }
            }
        }
        .navigationTitle(localizedString("dating.detailTitle"))
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchDetail(profileID: profileID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("dating.detailLoadFailed")
        }
    }

    private func submitPick() async {
        let normalizedContent = pickContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedContent.isEmpty else {
            actionMessage = localizedString("dating.pickContentRequired")
            return
        }
        guard normalizedContent.count <= 50 else {
            actionMessage = localizedString("dating.pickContentTooLong")
            return
        }

        isSubmittingPick = true
        defer { isSubmittingPick = false }

        do {
            try await viewModel.submitPick(profileID: profileID, content: normalizedContent)
            actionMessage = localizedString("dating.requestSent")
            pickContent = ""
            await loadDetail()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("dating.sendFailed")
        }
    }
}

private struct PublishDatingView: View {
    @ObservedObject var listViewModel: DatingHallViewModel
    @StateObject private var viewModel: PublishDatingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(
        listViewModel: DatingHallViewModel,
        viewModel: PublishDatingViewModel
    ) {
        self.listViewModel = listViewModel
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                if let image = viewModel.image {
                    ZStack(alignment: .topTrailing) {
                        previewImageView(image)

                        Button {
                            viewModel.image = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, DSColor.danger)
                        }
                        .offset(x: 6, y: -6)
                    }
                } else {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                            Text(localizedString("dating.addPhoto"))
                                .font(.caption)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Text(localizedString("dating.photoTip"))
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text(localizedString("dating.photoSection"))
            }

            Section {
                TextField(localizedString("dating.nickname"), text: $viewModel.nickname)
                Picker(localizedString("dating.grade"), selection: $viewModel.selectedGrade) {
                    ForEach(1 ..< 5) { grade in
                        Text(gradeText(grade)).tag(grade)
                    }
                }
                Picker(localizedString("dating.areaFilter"), selection: $viewModel.selectedArea) {
                    ForEach(DatingArea.allCases) { area in
                        Text(area.title).tag(area)
                    }
                }
                Picker(localizedString("dating.faculty"), selection: $viewModel.selectedFaculty) {
                    ForEach(viewModel.facultyOptions, id: \.self) { faculty in
                        Text(faculty).tag(faculty)
                    }
                }
                TextField(localizedString("dating.hometown"), text: $viewModel.hometown)
                TextField(localizedString("dating.qqOptional"), text: $viewModel.qq)
                TextField(localizedString("dating.wechatOptional"), text: $viewModel.wechat)
                TextField(localizedString("dating.bioPlaceholder"), text: $viewModel.content, axis: .vertical)
                    .lineLimit(4...6)
            } header: {
                Text(localizedString("dating.infoSection"))
            }

            if let message = viewModel.submitState.message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(viewModel.submitState.isSuccess ? DSColor.primary : DSColor.danger)
                }
            }
        }
        .navigationTitle(localizedString("dating.publishTitle"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    if viewModel.submitState.isSubmitting {
                        ProgressView()
                    } else {
                        Text(localizedString("common.submit"))
                    }
                }
                .disabled(viewModel.submitState.isSubmitting || !viewModel.isFormValid)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await loadSelectedImage(from: newItem) }
        }
        .alert(localizedString("dating.alertTitle"), isPresented: Binding(
            get: { viewModel.submitState.isSuccess },
            set: { isPresented in
                if !isPresented {
                    viewModel.submitState = .idle
                }
            }
        )) {
            Button(localizedString("dating.understood")) {
                viewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
        .task {
            await viewModel.loadFacultyOptionsIfNeeded()
        }
    }

    private func publish() async {
        guard let draft = viewModel.buildDraft() else { return }

        viewModel.submitState = .submitting

        do {
            try await listViewModel.publish(draft: draft)
            viewModel.submitState = .success(localizedString("dating.profilePublished"))
        } catch {
            viewModel.submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("delivery.publishFailed"))
        }
    }

    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { return }

        let contentType = item.supportedContentTypes.first
        let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
        let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
        viewModel.image = UploadImageAsset(
            fileName: "dating-\(UUID().uuidString).\(fileExtension)",
            mimeType: mimeType,
            data: data
        )
        selectedPhotoItem = nil
    }

    private func previewImageView(_ image: UploadImageAsset) -> some View {
        Group {
            if let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DSColor.subtitle)
                    }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func gradeText(_ grade: Int) -> String {
        switch grade {
        case 1:
            return localizedString("dating.grade1")
        case 2:
            return localizedString("dating.grade2")
        case 3:
            return localizedString("dating.grade3")
        default:
            return localizedString("dating.grade4")
        }
    }
}

#Preview {
    let container = AppContainer.preview
    NavigationStack {
        DatingView(viewModel: DatingHallViewModel(repository: MockDatingRepository()))
    }
    .environmentObject(container)
}
