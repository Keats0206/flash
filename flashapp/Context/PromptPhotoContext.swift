import SwiftUI
#if canImport(UIKit)
import PhotosUI
import UIKit
#endif

#if canImport(UIKit)
/// One user-selected photo with API-ready bytes and a thumbnail for the composer UI.
struct PromptPickablePhoto: Identifiable {
    let id = UUID()
    let thumbnail: UIImage
    let attachment: ImageContextAttachment

    static func load(from item: PhotosPickerItem) async -> PromptPickablePhoto? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data),
              let attachment = ui.normalizedJPEGForClaude()
        else { return nil }
        let thumbnail = ui.resized(maxDimension: 160)
        return PromptPickablePhoto(thumbnail: thumbnail, attachment: attachment)
    }
}

/// Horizontal thumbnails + add control for prompt surfaces (create flow / edit bar).
struct PromptPhotoAttachmentStrip: View {
    @Binding var photos: [PromptPickablePhoto]
    var maxCount: Int = 5

    @State private var pickingItem: PhotosPickerItem?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(photos) { p in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: p.thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                            )

                        Button {
                            photos.removeAll { $0.id == p.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.black.opacity(0.45))
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 7, y: -7)
                    }
                }

                if photos.count < maxCount {
                    PhotosPicker(selection: $pickingItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, height: 56)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add reference photo")
                }
            }
            .padding(.vertical, 2)
        }
        .onChange(of: pickingItem) { _, item in
            guard let item else { return }
            Task {
                if let p = await PromptPickablePhoto.load(from: item), photos.count < maxCount {
                    await MainActor.run {
                        photos.append(p)
                        pickingItem = nil
                    }
                } else {
                    await MainActor.run { pickingItem = nil }
                }
            }
        }
    }
}
#endif
