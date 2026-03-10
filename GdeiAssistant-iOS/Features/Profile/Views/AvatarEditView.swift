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
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    VStack(spacing: 16) {
                        avatarPreview
                        Text("建议选择清晰的正方形头像图片。上传后会同步更新普通头像与高清头像。")
                            .font(.footnote)
                            .foregroundStyle(DSColor.subtitle)
                    }
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("选择新头像", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(DSColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                if let data = selectedImageData {
                    DSButton(title: "上传头像", icon: "arrow.up.circle", isLoading: viewModel.submitState.isSubmitting) {
                        let asset = UploadImageAsset(
                            fileName: "avatar-\(UUID().uuidString).jpg",
                            mimeType: UTType.jpeg.preferredMIMEType ?? "image/jpeg",
                            data: data
                        )
                        Task { await viewModel.uploadAvatar(asset) }
                    }
                }

                if viewModel.avatarState.url != nil || selectedImageData != nil {
                    DSButton(title: "恢复默认头像", icon: "trash", variant: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .navigationTitle("头像管理")
        .task {
            await viewModel.load()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                selectedImageData = try? await newItem.loadTransferable(type: Data.self)
            }
        }
        .confirmationDialog("确认删除头像？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("恢复默认头像", role: .destructive) {
                Task { await viewModel.deleteAvatar() }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button("知道了") { viewModel.submitState = .idle }
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
