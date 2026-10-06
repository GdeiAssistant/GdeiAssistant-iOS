import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AvatarEditView: View {
    @StateObject private var viewModel: AvatarEditViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showDeleteConfirmation = false

    init(viewModel: AvatarEditViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                avatarPreview
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DSSpacing.md)
            } footer: {
                Text(localizedString("avatar.hint"))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            Section {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(localizedString("avatar.selectNew"), systemImage: "photo.badge.plus")
                        .foregroundStyle(DSColor.primary)
                }

                if viewModel.avatarState.url != nil || selectedImageData != nil {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(localizedString("avatar.restoreDefault"), systemImage: "trash")
                            .foregroundStyle(DSColor.danger)
                    }
                }
            } footer: {
                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .foregroundStyle(DSColor.danger)
                }
            }

            if let data = selectedImageData {
                Section {
                    DSButton(title: localizedString("avatar.upload"), icon: "arrow.up.circle", isLoading: viewModel.submitState.isSubmitting) {
                        let asset = UploadImageAsset(
                            fileName: "avatar-\(UUID().uuidString).jpg",
                            mimeType: UTType.jpeg.preferredMIMEType ?? "image/jpeg",
                            data: data
                        )
                        Task { await viewModel.uploadAvatar(asset) }
                    }
                    .dsActionRow()
                }
            }
        }
        .dsForm()
        .navigationTitle(localizedString("avatar.title"))
        .task {
            await viewModel.load()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                selectedImageData = try? await newItem.loadTransferable(type: Data.self)
            }
        }
        .confirmationDialog(localizedString("avatar.confirmDelete"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(localizedString("avatar.restoreDefault"), role: .destructive) {
                Task { await viewModel.deleteAvatar() }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button(localizedString("common.understood")) { viewModel.submitState = .idle }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let data = selectedImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        } else if let url = viewModel.avatarState.url {
            DSAvatarView(urlString: url, size: 120)
        } else {
            DSAvatarView(urlString: nil, size: 120)
        }
    }
}
