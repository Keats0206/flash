import SwiftUI
import AVKit
import AVFoundation
#if canImport(MapKit)
import MapKit
#endif

// MARK: - URL helper

private func flashURL(from string: String?) -> URL? {
    guard var s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
    if !s.contains("://") { s = "https://" + s }
    return URL(string: s)
}

// MARK: - Image

struct CImage: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var url: URL? { flashURL(from: c.src ?? c.content) }
    private var radius: CGFloat {
        c.style == "bleed" ? 0 : CGFloat(c.cornerRadius ?? 12)
    }

    var body: some View {
        if c.style == "polaroid" {
            baseImage
                .padding(8)
                .background(Color.systemBg)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        } else {
            baseImage
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(borderOverlay)
                .overlay(posterOverlay)
        }
    }

    private var baseImage: some View {
        Group {
            if let url {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(maxWidth: .infinity, minHeight: c.minHeight ?? 160)
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: c.minHeight ?? 160)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(borderColor, lineWidth: borderWidth)
    }

    @ViewBuilder
    private var posterOverlay: some View {
        if c.style == "poster" {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.18)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var borderColor: Color {
        if c.border != nil { return c.resolvedBorder(palette: palette) }
        if c.style == "poster" { return palette.accent.opacity(0.22) }
        return .clear
    }

    private var borderWidth: CGFloat {
        (c.border != nil || c.style == "poster") ? 1 : 0
    }

    var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: c.icon ?? "photo")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Video

struct CVideo: View {
    let c: Component
    @State private var player: AVPlayer?

    private var url: URL? { flashURL(from: c.src ?? c.content) }

    var body: some View {
        Group {
            if let url {
                Group {
                    if let player {
                        VideoPlayer(player: player)
                    } else {
                        ProgressView().frame(height: c.minHeight ?? 200)
                    }
                }
                .onAppear { player = AVPlayer(url: url) }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            } else {
                missingMedia(label: "Video URL missing")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: c.minHeight ?? 200)
        .clipShape(RoundedRectangle(cornerRadius: c.cornerRadius ?? 12))
    }

    func missingMedia(label: String) -> some View {
        ZStack {
            Color.secondary.opacity(0.12)
            VStack(spacing: 8) {
                Image(systemName: "video.slash")
                    .font(.title)
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Audio

struct CAudio: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var player: AVPlayer?
    @State private var playing = false

    private var url: URL? { flashURL(from: c.src ?? c.content) }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: toggle) {
                Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                Text(c.content ?? "Audio")
                    .font(.subheadline.weight(.semibold))
                if let sub = c.subtitle {
                    Text(sub).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(c.padding ?? 14)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 14)
        .onAppear { prepare() }
        .onDisappear { stop() }
    }

    func prepare() {
        guard let url else { return }
        player = AVPlayer(url: url)
    }

    func stop() {
        player?.pause()
        playing = false
    }

    func toggle() {
        guard let player else { return }
        if playing {
            player.pause()
        } else {
            player.play()
        }
        playing.toggle()
    }
}

// MARK: - Gallery

struct CGallery: View {
    let c: Component

    private var imageURLs: [URL] {
        if let urls = c.urls, !urls.isEmpty {
            return urls.compactMap { flashURL(from: $0) }
        }
        return (c.items ?? []).compactMap { flashURL(from: $0.mediaURL ?? $0.value) }
    }

    var body: some View {
        Group {
            if imageURLs.isEmpty {
                Text("No images")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if c.style == "collage" {
                VStack(spacing: c.spacing ?? 8) {
                    if let first = imageURLs.first {
                        galleryImage(first)
                            .frame(height: max(140, (c.minHeight ?? 220) * 0.6))
                    }
                    if imageURLs.count > 1 {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: c.spacing ?? 8) {
                            ForEach(Array(imageURLs.dropFirst().enumerated()), id: \.offset) { _, u in
                                galleryImage(u)
                                    .frame(height: 110)
                            }
                        }
                    }
                }
            } else {
                TabView {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { _, u in
                        galleryImage(u)
                    }
                }
                .pageStyle()
                .frame(height: c.minHeight ?? 220)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: c.cornerRadius ?? 14))
    }

    private func galleryImage(_ url: URL) -> some View {
        CachedAsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            default:
                Color.secondary.opacity(0.15)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: c.style == "collage" ? 10 : (c.cornerRadius ?? 14), style: .continuous))
    }
}

// MARK: - Map (static region)

#if os(iOS)
struct CMap: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var coord: CLLocationCoordinate2D {
        let lat = c.latitude ?? 37.7749
        let lon = c.longitude ?? -122.4194
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var span: MKCoordinateSpan {
        let delta: Double
        if let v = c.value, v >= 0.01, v <= 2 {
            delta = v
        } else {
            delta = 0.05
        }
        return MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: coord, span: span))) {
            Marker(c.content ?? "Pin", coordinate: coord)
                .tint(palette.accent)
        }
        .mapStyle(.standard)
        .frame(maxWidth: .infinity)
        .frame(height: c.minHeight ?? 180)
        .clipShape(RoundedRectangle(cornerRadius: c.cornerRadius ?? 14))
    }
}
#else
struct CMap: View {
    let c: Component
    var body: some View {
        ComponentView(c: Component(type: "text", content: c.content ?? "Map (iOS only)"))
    }
}
#endif

// MARK: - Chart (bars from items)

struct CChart: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var points: [(String, Double)] {
        (c.items ?? []).compactMap { item -> (String, Double)? in
            guard let v = item.value.flatMap(Double.init) else { return nil }
            return (item.label, v)
        }
    }

    private var maxVal: Double {
        let m = points.map(\.1).max() ?? 1
        return m > 0 ? m : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let t = c.content {
                Text(t).font(.subheadline.weight(.semibold))
            }
            if points.isEmpty {
                Text("Add items with numeric value")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let isLine = (c.style ?? "") == "line"
                if isLine {
                    lineChart
                } else {
                    barChart
                }
            }
        }
        .padding(c.padding ?? 12)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 14)
    }

    var barChart: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(palette.accent.opacity(0.85))
                            .frame(height: max(4, geo.size.height * 0.75 * (p.1 / maxVal)))
                        Text(p.0)
                            .font(.system(size: 9))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: c.minHeight ?? 140)
    }

    var lineChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height * 0.7
            let step = points.count > 1 ? w / CGFloat(points.count - 1) : w
            Path { path in
                for (i, p) in points.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - CGFloat(p.1 / maxVal) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(palette.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .frame(height: c.minHeight ?? 120)
    }
}

// MARK: - Calendar

struct CCalendar: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var selected = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let t = c.content {
                Text(t).font(.subheadline.weight(.semibold))
            }
            DatePicker(
                "",
                selection: $selected,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(palette.accent)
        }
        .padding(c.padding ?? 8)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 14)
    }
}
