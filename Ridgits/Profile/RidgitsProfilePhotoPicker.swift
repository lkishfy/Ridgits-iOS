import SwiftUI
import PhotosUI
import UIKit

struct RidgitsProfilePhotoPicker: View {
    @Binding var imageURL: String
    var size: CGFloat = 72

    @State private var selectedItem: PhotosPickerItem?
    @State private var localPreview: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 14) {
                    photoPreview
                    VStack(alignment: .leading, spacing: 4) {
                        Text(actionLabel)
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Choose a photo from your library")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    if isUploading {
                        ProgressView()
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(RidgitsColors.textMuted)
                    }
                }
                .padding(12)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .disabled(isUploading)

            if let uploadError {
                Text(uploadError)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.destructive)
            }

            Text("You must use a profile photo that matches your license or you won't be able to chat.")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: selectedItem) { _, item in
            Task { await handleSelection(item) }
        }
    }

    private var actionLabel: String {
        if isUploading { return "Uploading…" }
        return hasPhoto ? "Change photo" : "Add photo"
    }

    private var hasPhoto: Bool {
        localPreview != nil || !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private var photoPreview: some View {
        Group {
            if let localPreview {
                Image(uiImage: localPreview)
                    .resizable()
                    .scaledToFill()
            } else {
                RidgitsCachedProfileImage(remoteURL: imageURL.isEmpty ? nil : imageURL) {
                    RidgitsColors.hoverSurface
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.35))
                                .foregroundStyle(RidgitsColors.textMuted)
                        )
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.border, lineWidth: 1)
        )
    }

    @MainActor
    private func handleSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploading = true
        uploadError = nil
        defer { isUploading = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let jpeg = uiImage.jpegData(compressionQuality: 0.85) else {
            uploadError = "Could not load that photo. Try another image."
            return
        }

        localPreview = uiImage
        do {
            let urls = try await RidgitsQuickToolsService.shared.uploadImages([jpeg], folder: "profile_images")
            guard let url = urls.first else {
                uploadError = "Upload failed. Please try again."
                localPreview = nil
                return
            }
            imageURL = url
        } catch {
            localPreview = nil
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("permission") ||
                message.localizedCaseInsensitiveContains("unauthorized") {
                uploadError = "Could not upload your photo. Please sign in again and try once more."
            } else {
                uploadError = message
            }
        }
    }
}
