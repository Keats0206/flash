import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Curated Unsplash art (hotlink-friendly URLs)

enum HeaderArt {
    /// Landscape / texture photos that read well behind title + icon.
    private static let unsplashSources: [String] = [
        "https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=1600&q=85",
        "https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f?auto=format&fit=crop&w=1600&q=85",
        "https://images.unsplash.com/photo-1508610048659-a06b669e3321?auto=format&fit=crop&w=1600&q=85",
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1600&q=85",
        "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1600&q=85",
    ]

    static func unsplashURL(forAppId id: UUID) -> URL {
        let i = stableBucket(for: id, modulo: unsplashSources.count)
        return URL(string: unsplashSources[i])!
    }

    private static func stableBucket(for id: UUID, modulo: Int) -> Int {
        var h: UInt64 = 1469598103934665603
        withUnsafeBytes(of: id.uuid) { buf in
            for b in buf {
                h ^= UInt64(b)
                h &*= 1099511628211
            }
        }
        return Int(h % UInt64(max(modulo, 1)))
    }
}

// MARK: - Fluted glass (vertical prism strips)

/// Approximates ribbed / fluted glass by shifting each vertical slice of a photo (similar intent to Paper’s “lines + prism” shader).
struct FlutedPhotoHeaderBackground: View {
    let imageURL: URL
    var stripCount: Int = 48
    /// Horizontal shift amplitude per strip (points). Tune with screen width — ~8–12 reads well on phone.
    var distortion: CGFloat = 10
    var highlightOpacity: Double = 0.10
    var shadowOpacity: Double = 0.24

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if let image {
                    flutedStack(image: image, width: w, height: h)
                    ribLighting(width: w, height: h)
                } else {
                    Color.black.opacity(0.25)
                }
            }
            .frame(width: w, height: h)
        }
        .task(id: imageURL.absoluteString) {
            await load()
        }
    }

    @ViewBuilder
    private func flutedStack(image: UIImage, width w: CGFloat, height h: CGFloat) -> some View {
        let strips = max(18, min(72, stripCount))
        let stripW = w / CGFloat(strips)

        HStack(spacing: 0) {
            ForEach(0..<strips, id: \.self) { i in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: w, height: h)
                    .offset(x: prismOffset(index: i) - CGFloat(i) * stripW)
                    .frame(width: stripW, height: h, alignment: .leading)
                    .clipped()
            }
        }
        .frame(width: w, height: h)
    }

    /// Smooth prism-like displacement across ribs (maps to “distortionShape: prism” in Paper’s controls).
    private func prismOffset(index i: Int) -> CGFloat {
        distortion * CGFloat(sin(Double(i) * 0.72))
    }

    private func ribLighting(width w: CGFloat, height h: CGFloat) -> some View {
        let strips = max(18, min(72, stripCount))
        let stripW = w / CGFloat(strips)

        return HStack(spacing: 0) {
            ForEach(0..<strips, id: \.self) { _ in
                LinearGradient(
                    colors: [
                        Color.white.opacity(highlightOpacity),
                        Color.clear,
                        Color.black.opacity(shadowOpacity),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: stripW, height: h)
                .blendMode(.overlay)
            }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    private func load() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let ui = UIImage(data: data) {
                await MainActor.run { image = ui }
            }
        } catch {
            await MainActor.run { image = nil }
        }
    }
}

#if DEBUG
struct FlutedGlassHeader_Previews: PreviewProvider {
    static var previews: some View {
        FlutedPhotoHeaderBackground(imageURL: HeaderArt.unsplashURL(forAppId: UUID()))
            .frame(height: 220)
            .clipShape(Rectangle())
    }
}
#endif
