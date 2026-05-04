import SwiftUI

// MARK: - WizardStep (used by type "wizard")

/// One screen in a first-class multi-step flow. Use `children` or JSON alias `body` for step content.
struct WizardStep: Codable, Identifiable {
    let id: String
    let title: String?
    let children: [Component]

    init(id: String? = nil, title: String?, children: [Component]) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.children = children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try c.decodeIfPresent(String.self, forKey: .title)
        if let ch = try c.decodeIfPresent([Component].self, forKey: .children) {
            children = Component.normalizedTree(ch, parentPath: id)
        } else if let b = try c.decodeIfPresent([Component].self, forKey: .body) {
            children = Component.normalizedTree(b, parentPath: id)
        } else {
            children = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encode(children, forKey: .children)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, children, body
    }
}

// MARK: - MicroApp

struct MicroApp: Identifiable, Codable {
    let id: UUID
    let title: String
    let icon: String
    let accent: String
    let body: [Component]
    /// Original user idea from create flow; shown under the title in the gallery (truncated).
    let prompt: String?

    init(id: UUID = UUID(), title: String, icon: String, accent: String, body: [Component], prompt: String? = nil) {
        self.id = id; self.title = title; self.icon = icon
        self.accent = accent
        self.body = Component.normalizedTree(body, parentPath: "body")
        self.prompt = prompt
    }
}

// MARK: - Component (recursive layout tree node)

struct Component: Codable {
    let id: String?
    let type: String
    // layout
    let children: [Component]?
    // interactive leaves
    let items: [LeafItem]?
    // display
    let content: String?      // text / badge / emoji character
    let icon: String?         // SF Symbol name
    let style: String?        // display|title|heading|label|body|caption|mono
    let weight: String?       // regular|medium|semibold|bold|black
    let color: String?        // primary|secondary|accent|success|danger|warning
    // container
    let background: String?   // tinted|secondary|tertiary|elevated|none
    let alignment: String?    // leading|center|trailing
    let padding: Double?
    let cornerRadius: Double?
    // layout metrics
    let columns: Int?
    let spacing: Double?
    let itemWidth: Double?
    let opacity: Double?
    let rotation: Double?
    let scale: Double?
    let offsetX: Double?
    let offsetY: Double?
    let minWidth: Double?
    let maxWidth: Double?
    let aspectRatio: Double?
    let zIndex: Double?
    // new scalar + card fields
    let value: Double?        // 0.0–1.0 for progress/meter; 0–5 for rating; stepper start
    let border: String?       // card stroke color: accent|secondary|hex string
    let shadow: Double?       // card drop shadow radius (nil = no shadow)
    let minHeight: Double?    // meter ring diameter; button height override
    let action: String?       // future: "url:..." — ignored for now
    let name: String?         // binding key for aiquery template interpolation
    // media / geo / misc
    let src: String?          // primary URL: image, video, audio, share
    let subtitle: String?   // secondary line (profile, comment meta, CTA)
    let urls: [String]?       // gallery images, ordered
    let latitude: Double?
    let longitude: Double?
    let duration: Double?     // timer seconds, story hint, etc.
    // flows
    let steps: [WizardStep]?  // type "wizard" — ordered steps with title + children each
    let mode: String?         // type "aiquery": "replace" (default) vs "append" for query results

    init(
        id: String? = nil,
        type: String,
        children: [Component]? = nil,
        items: [LeafItem]? = nil,
        content: String? = nil,
        icon: String? = nil,
        style: String? = nil,
        weight: String? = nil,
        color: String? = nil,
        background: String? = nil,
        alignment: String? = nil,
        padding: Double? = nil,
        cornerRadius: Double? = nil,
        columns: Int? = nil,
        spacing: Double? = nil,
        itemWidth: Double? = nil,
        opacity: Double? = nil,
        rotation: Double? = nil,
        scale: Double? = nil,
        offsetX: Double? = nil,
        offsetY: Double? = nil,
        minWidth: Double? = nil,
        maxWidth: Double? = nil,
        aspectRatio: Double? = nil,
        zIndex: Double? = nil,
        value: Double? = nil,
        border: String? = nil,
        shadow: Double? = nil,
        minHeight: Double? = nil,
        action: String? = nil,
        name: String? = nil,
        src: String? = nil,
        subtitle: String? = nil,
        urls: [String]? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        duration: Double? = nil,
        steps: [WizardStep]? = nil,
        mode: String? = nil
    ) {
        self.id = id
        self.type = type
        self.children = children.map { Component.normalizedTree($0, parentPath: id ?? type) }
        self.items = items
        self.content = content; self.icon = icon; self.style = style
        self.weight = weight; self.color = color; self.background = background
        self.alignment = alignment; self.padding = padding; self.cornerRadius = cornerRadius
        self.columns = columns; self.spacing = spacing; self.itemWidth = itemWidth
        self.opacity = opacity; self.rotation = rotation; self.scale = scale
        self.offsetX = offsetX; self.offsetY = offsetY
        self.minWidth = minWidth; self.maxWidth = maxWidth
        self.aspectRatio = aspectRatio; self.zIndex = zIndex
        self.value = value; self.border = border; self.shadow = shadow
        self.minHeight = minHeight; self.action = action; self.name = name
        self.src = src; self.subtitle = subtitle; self.urls = urls
        self.latitude = latitude; self.longitude = longitude; self.duration = duration
        self.steps = steps; self.mode = mode
    }

    var kids: [Component] { children ?? [] }
}

extension Component {
    static func normalizedTree(_ components: [Component], parentPath: String) -> [Component] {
        components.enumerated().map { index, component in
            component.normalized(path: "\(parentPath).\(index)")
        }
    }

    func normalized(path: String) -> Component {
        let resolvedID = (id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? id : path
        let resolvedChildren = children.map { childComponents in
            childComponents.enumerated().map { index, child in
                child.normalized(path: "\(resolvedID ?? path).\(index)")
            }
        }
        let resolvedSteps = steps?.enumerated().map { index, step in
            let stepID = step.id.isEmpty ? "\(resolvedID ?? path).step.\(index)" : step.id
            return WizardStep(
                id: stepID,
                title: step.title,
                children: Component.normalizedTree(step.children, parentPath: stepID)
            )
        }

        return Component(
            id: resolvedID,
            type: type,
            children: resolvedChildren,
            items: items,
            content: content,
            icon: icon,
            style: style,
            weight: weight,
            color: color,
            background: background,
            alignment: alignment,
            padding: padding,
            cornerRadius: cornerRadius,
            columns: columns,
            spacing: spacing,
            itemWidth: itemWidth,
            opacity: opacity,
            rotation: rotation,
            scale: scale,
            offsetX: offsetX,
            offsetY: offsetY,
            minWidth: minWidth,
            maxWidth: maxWidth,
            aspectRatio: aspectRatio,
            zIndex: zIndex,
            value: value,
            border: border,
            shadow: shadow,
            minHeight: minHeight,
            action: action,
            name: name,
            src: src,
            subtitle: subtitle,
            urls: urls,
            latitude: latitude,
            longitude: longitude,
            duration: duration,
            steps: resolvedSteps,
            mode: mode
        )
    }
}

extension Component {
    var resolvedFont: Font {
        let base: Font
        switch style ?? "body" {
        case "hero":    base = .system(size: 46, weight: .black, design: .rounded)
        case "display": base = .system(size: 40, weight: .black)
        case "title":   base = .title2
        case "heading": base = .headline
        case "label":   base = .subheadline
        case "kicker":  base = .system(size: 12, weight: .semibold, design: .rounded)
        case "caption": base = .caption
        case "quote":   base = .system(.title3, design: .serif)
        case "stat":    base = .system(size: 28, weight: .black, design: .rounded)
        case "mono":    base = .system(.body, design: .monospaced)
        default:        base = .body
        }
        switch weight {
        case "medium":   return base.weight(.medium)
        case "semibold": return base.weight(.semibold)
        case "bold":     return base.weight(.bold)
        case "black":    return base.weight(.black)
        default:         return base
        }
    }

    func resolvedColor(palette: SkinPalette) -> Color {
        switch color ?? "primary" {
        case "secondary": return .secondary
        case "inverse":   return .white
        case "accent":    return palette.accent
        case "success":   return palette.success
        case "danger":    return palette.danger
        case "warning":   return palette.warning
        default:          return .primary
        }
    }

    func resolvedBg(palette: SkinPalette) -> Color {
        switch background {
        case "accent":   return palette.accent.opacity(0.16)
        case "tinted":   return palette.accent.opacity(0.1)
        case "tertiary": return Color.tertiaryBg
        case "elevated": return Color.systemBg
        case "none":     return .clear
        default:         return Color.secondaryBg
        }
    }

    func resolvedBorder(palette: SkinPalette) -> Color {
        guard let border else { return .clear }
        switch border {
        case "accent":    return palette.accent
        case "secondary": return Color.secondary.opacity(0.2)
        default:          return Color(hex: border)
        }
    }

    var resolvedHAlign: HorizontalAlignment {
        switch alignment {
        case "center":   return .center
        case "trailing": return .trailing
        default:         return .leading
        }
    }

    var resolvedAlignment: Alignment {
        switch alignment {
        case "center":   return .center
        case "trailing": return .trailing
        default:         return .leading
        }
    }

    var resolvedOpacity: Double {
        min(1, max(0, opacity ?? 1))
    }
}

// MARK: - Share / Import

extension MicroApp {
    func normalized() -> MicroApp {
        MicroApp(id: id, title: title, icon: icon, accent: accent, body: body, prompt: prompt)
    }

    func flashShareURL() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "flash://import?data=\(b64)")
    }

    static func decode(fromFlashURL url: URL) -> MicroApp? {
        guard url.scheme == "flash",
              url.host == "import",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let b64raw = components.queryItems?.first(where: { $0.name == "data" })?.value
        else { return nil }

        var b64 = b64raw
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let rem = b64.count % 4
        if rem > 0 { b64 += String(repeating: "=", count: 4 - rem) }

        guard let data = Data(base64Encoded: b64),
              let decoded = try? JSONDecoder().decode(MicroApp.self, from: data)
        else { return nil }

        return MicroApp(title: decoded.title, icon: decoded.icon,
                        accent: decoded.accent, body: decoded.body,
                        prompt: decoded.prompt)
    }
}

// MARK: - LeafItem (used by checklist / swipe / pager / table / tagcloud)

struct LeafItem: Codable, Identifiable {
    let id: String
    let label: String
    let subtitle: String?
    let value: String?
    let emoji: String?
    let icon: String?   // SF Symbol — used by table rows + checklist
    let color: String?  // accent|success|danger|warning — per-row tint
    let mediaURL: String? // image URL for story, gallery slide, attachment

    init(id: String, label: String, subtitle: String? = nil,
         value: String? = nil, emoji: String? = nil,
         icon: String? = nil, color: String? = nil,
         mediaURL: String? = nil) {
        self.id = id; self.label = label; self.subtitle = subtitle
        self.value = value; self.emoji = emoji
        self.icon = icon; self.color = color
        self.mediaURL = mediaURL
    }
}
