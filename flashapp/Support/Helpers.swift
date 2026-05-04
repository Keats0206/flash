import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Flash visual language

/// Neutral chrome stays quiet; `MicroApp.accent` carries brand personality.
enum FlashPalette {
    /// Light mode canvas — ultra-light gray.
    static let canvasLight = Color(hex: "#F5F5F7")
    /// Dark mode canvas — off-black (not pure `#000`).
    static let canvasDark = Color(hex: "#141415")
    /// Cards / inset fields on dark canvas.
    static let surfaceDark = Color(hex: "#1C1C1E")

    static func canvas(for scheme: ColorScheme) -> Color {
        scheme == .dark ? canvasDark : canvasLight
    }

    /// Behind the lifted micro-app card on the detail screen (grouped gray in light mode).
    #if os(iOS)
    static var microAppDetailChrome: Color { Color(UIColor.systemGroupedBackground) }
    /// White / primary surface used for the lifted card itself.
    static var microAppCardSurface: Color { Color(UIColor.systemBackground) }
    #else
    static var microAppDetailChrome: Color { canvasLight }
    static var microAppCardSurface: Color { Color.white }
    #endif

    // Brand accents — use exactly one per app as `accent` in JSON.
    static let blue = Color(hex: "#4A8EDB")
    static let redOrange = Color(hex: "#FF3B30")
    static let warmYellow = Color(hex: "#F4B95E")
    static let pink = Color(hex: "#E56A9A")
    static let dustyBlue = Color(hex: "#8FAFBE")
    static let limeGreen = Color(hex: "#B6DE6F")
    static let softPink = Color(hex: "#EFC1C9")
    static let brightYellow = Color(hex: "#F5E51B")

    /// Preferred accent hex strings for LLM prompts and samples.
    static let accentHexes: [String] = [
        "#4A8EDB", "#FF3B30", "#F4B95E", "#E56A9A",
        "#8FAFBE", "#B6DE6F", "#EFC1C9", "#F5E51B",
    ]
}

// MARK: - Adaptive Colors

extension Color {
    #if os(iOS)
    static let secondaryBg = Color(UIColor.secondarySystemBackground)
    static let tertiaryBg  = Color(UIColor.tertiarySystemBackground)
    static let tertiaryFg  = Color(UIColor.tertiaryLabel)
    static let systemBg    = Color(UIColor.systemBackground)
    #else
    static let secondaryBg = Color.secondary.opacity(0.12)
    static let tertiaryBg  = Color.secondary.opacity(0.07)
    static let tertiaryFg  = Color.secondary.opacity(0.5)
    static let systemBg    = Color.white
    #endif

    #if canImport(UIKit)
    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    #endif

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (100, 100, 100)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - View Helpers

extension View {
    func hideNavBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    func pageStyle() -> some View {
        #if os(iOS)
        self.tabViewStyle(.page(indexDisplayMode: .always))
        #else
        self
        #endif
    }

    func flashComponentTransform(_ c: Component) -> some View {
        let minWidth = c.minWidth.map { CGFloat($0) }
        let maxWidth = c.maxWidth.map { CGFloat($0) }
        let aspectRatio = c.aspectRatio.map { CGFloat($0) }
        let scale = CGFloat(c.scale ?? 1)
        let rotation = Angle(degrees: c.rotation ?? 0)
        let offsetX = CGFloat(c.offsetX ?? 0)
        let offsetY = CGFloat(c.offsetY ?? 0)
        let zDepth: Double = c.zIndex ?? 0
    
        return self
            .frame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                alignment: c.resolvedAlignment
            )
            .flashOptionalAspectRatio(aspectRatio)
            .flashOptionalScale(scale, alignment: c.alignment)
            .flashOptionalRotation(rotation, degrees: c.rotation)
            .opacity(c.resolvedOpacity)
            .flashOptionalOffset(x: offsetX, y: offsetY)
            .zIndex(zDepth)
    }

    private func flashUnitPoint(from alignment: String?) -> UnitPoint {
        switch alignment {
        case "center":
            return .center
        case "trailing":
            return .trailing
        default:
            return .leading
        }
    }

    @ViewBuilder
    private func flashOptionalAspectRatio(_ aspectRatio: CGFloat?) -> some View {
        if let aspectRatio {
            self.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            self
        }
    }

    @ViewBuilder
    private func flashOptionalScale(_ scale: CGFloat, alignment: String?) -> some View {
        if scale != 1 {
            self.scaleEffect(scale, anchor: flashUnitPoint(from: alignment))
        } else {
            self
        }
    }

    @ViewBuilder
    private func flashOptionalRotation(_ rotation: Angle, degrees: Double?) -> some View {
        if let degrees, degrees != 0 {
            self.rotationEffect(rotation)
        } else {
            self
        }
    }

    @ViewBuilder
    private func flashOptionalOffset(x: CGFloat, y: CGFloat) -> some View {
        if x != 0 || y != 0 {
            self.offset(x: x, y: y)
        } else {
            self
        }
    }
}

// MARK: - Claude vision payloads (iOS)

#if canImport(UIKit)
extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Downscale and JPEG-encode for Anthropic image blocks (≤ ~8MB typical limits).
    func normalizedJPEGForClaude(maxDimension: CGFloat = 2048, quality: CGFloat = 0.82) -> ImageContextAttachment? {
        let scaled = resized(maxDimension: maxDimension)
        guard let data = scaled.jpegData(compressionQuality: quality) else { return nil }
        return ImageContextAttachment(data: data, mediaType: "image/jpeg")
    }
}
#endif
