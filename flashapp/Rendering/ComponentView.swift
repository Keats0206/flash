import SwiftUI

// MARK: - Dispatcher

struct ComponentView: View {
    let c: Component

    var body: some View {
        renderedComponent
            .flashComponentTransform(c)
    }

    @ViewBuilder
    private var renderedComponent: some View {
        switch c.type {
        case "text":      CText(c: c)
        case "badge":     CBadge(c: c)
        case "icon":      CIcon(c: c)
        case "button":    CButton(c: c)
        case "progress":  CProgress(c: c)
        case "rating":    CRating(c: c)
        case "meter":     CMeter(c: c)
        case "avatar":    CAvatar(c: c)
        case "table":     CTable(c: c)
        case "divider":   Divider()
        case "spacer":    Spacer(minLength: c.spacing ?? 0)
        case "hstack":    CHStack(c: c)
        case "vstack":    CVStack(c: c)
        case "zstack":    CZStack(c: c)
        case "grid":      CGrid(c: c)
        case "hscroll":   CHScroll(c: c)
        case "card":      CCard(c: c)
        case "checklist": ChecklistView(items: c.items ?? [])
        case "swipe":     SwipeView(items: c.items ?? [])
        case "pager":     PagerView(items: c.items ?? [])
        case "toggle":    ToggleView(c: c)
        case "stepper":   StepperView(c: c)
        case "input":     InputView(c: c)
        case "tagcloud":  TagCloudView(c: c)
        case "aiquery":   AiQueryView(c: c)
        case "image":     CImage(c: c)
        case "video":     CVideo(c: c)
        case "audio":     CAudio(c: c)
        case "gallery":   CGallery(c: c)
        case "map":       CMap(c: c)
        case "chart":     CChart(c: c)
        case "calendar":  CCalendar(c: c)
        case "section":   CSection(c: c)
        case "list":      CList(c: c)
        case "tabs":      CTabs(c: c)
        case "accordion": CAccordion(c: c)
        case "sheet":     CSheet(c: c)
        case "modal":     CModal(c: c)
        case "nav":       CNav(c: c)
        case "comment":   CComment(c: c)
        case "thread":    CThread(c: c)
        case "reaction":  CReactionBar(c: c)
        case "share":     CShare(c: c)
        case "vote":      CVote(c: c)
        case "poll":      CPoll(c: c)
        case "profile":   CProfile(c: c)
        case "presence":  CPresence(c: c)
        case "cta":       CCTA(c: c)
        case "fab":       CFloatingButton(c: c)
        case "timer":     CTimer(c: c)
        case "counter":   CCounter(c: c)
        case "progress_ring": CProgressRing(c: c)
        case "form":      CForm(c: c)
        case "select":    CSelect(c: c)
        case "date":      CDatePicker(c: c)
        case "upload":    CUpload(c: c)
        case "confetti":  CConfetti(c: c)
        case "tooltip":   CTooltip(c: c)
        case "badge_stack": CBadgeStack(c: c)
        case "story":     CStory(c: c)
        case "wizard":    CWizard(c: c)
        default:          CUnsupported(c: c)
        }
    }
}

struct CUnsupported: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        #if DEBUG
        Text("Unsupported component: \(c.type)")
            .font(.caption.weight(.semibold))
            .foregroundColor(palette.danger)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(palette.danger.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.danger.opacity(0.22), lineWidth: 1)
            )
            .cornerRadius(10)
        #else
        EmptyView()
        #endif
    }
}

// MARK: - Display Atoms

struct CText: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        Text(displayText)
            .font(c.resolvedFont)
            .foregroundColor(c.resolvedColor(palette: palette))
            .tracking(c.style == "kicker" ? 1.2 : 0)
            .lineSpacing(c.style == "quote" ? 4 : 0)
            .multilineTextAlignment(textAlignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var displayText: String {
        if c.style == "kicker" {
            return (c.content ?? "").uppercased()
        }
        return c.content ?? ""
    }

    private var textAlignment: TextAlignment {
        switch c.alignment {
        case "center":
            return .center
        case "trailing":
            return .trailing
        default:
            return .leading
        }
    }
}

struct CBadge: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var fg: Color {
        if c.color == nil || c.color == "primary" { return palette.accent }
        return c.resolvedColor(palette: palette)
    }

    var body: some View {
        Text(c.content ?? "")
            .font(.caption.weight(.semibold))
            .foregroundColor(foreground)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
            .overlay(borderOverlay)
            .cornerRadius(c.style == "sticker" ? 16 : 20)
            .rotationEffect(.degrees(c.style == "sticker" ? -4 : 0))
            .shadow(color: c.style == "sticker" ? fg.opacity(0.18) : .clear, radius: 8, x: 0, y: 4)
    }

    private var foreground: Color {
        switch c.style {
        case "solid":
            return .white
        default:
            return fg
        }
    }

    private var horizontalPadding: CGFloat {
        c.style == "sticker" ? 12 : 10
    }

    private var verticalPadding: CGFloat {
        c.style == "sticker" ? 6 : 4
    }

    @ViewBuilder
    private var background: some View {
        switch c.style {
        case "solid":
            fg
        case "outline":
            Color.clear
        case "sticker":
            Color.systemBg
        default:
            fg.opacity(0.12)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch c.style {
        case "outline":
            Capsule().stroke(fg.opacity(0.45), lineWidth: 1.2)
        case "sticker":
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(fg.opacity(0.22), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

struct CIcon: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        Image(systemName: c.icon ?? "circle")
            .font(c.resolvedFont)
            .foregroundColor(c.resolvedColor(palette: palette))
    }
}

struct CButton: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var pressed = false
    private var tint: Color {
        if c.color == nil || c.color == "primary" { return palette.accent }
        return c.resolvedColor(palette: palette)
    }

    var body: some View {
        Button(action: {
            FlashActionRuntime.perform(from: c, fallbackText: c.content)
            withAnimation(.spring(response: 0.2)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring()) { pressed = false }
            }
        }) {
            HStack(spacing: 8) {
                if let icon = c.icon { Image(systemName: icon) }
                Text(c.content ?? "Button")
            }
            .font(.headline)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(c.padding ?? 14)
            .background(background)
            .overlay(borderOverlay)
            .cornerRadius(c.style == "pill" ? 999 : (c.cornerRadius ?? 14))
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.97 : 1.0)
    }

    private var foreground: Color {
        switch c.style {
        case "solid":
            return .white
        default:
            return tint
        }
    }

    @ViewBuilder
    private var background: some View {
        switch c.style {
        case "solid":
            tint
        case "outline":
            Color.clear
        case "pill":
            tint.opacity(0.12)
        default:
            c.resolvedBg(palette: palette)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch c.style {
        case "outline":
            RoundedRectangle(cornerRadius: c.cornerRadius ?? 14, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1.2)
        default:
            EmptyView()
        }
    }
}

struct CProgress: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var displayed = false
    var fg: Color { c.resolvedColor(palette: palette) }
    var val: Double { min(1, max(0, c.value ?? 0)) }
    var body: some View {
        VStack(spacing: 6) {
            if let label = c.content {
                HStack {
                    Text(label).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(val * 100))%").font(.caption.weight(.semibold))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(fg)
                        .frame(width: geo.size.width * (displayed ? val : 0))
                        .animation(.spring(response: 0.5), value: displayed)
                }
            }
            .frame(height: 8)
        }
        .onAppear { displayed = true }
    }
}

struct CRating: View {
    let c: Component
    var val: Double { c.value ?? 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    let d = Double(i)
                    Image(systemName: val >= d + 1 ? "star.fill" :
                                      val >= d + 0.5 ? "star.leadinghalf.filled" : "star")
                        .foregroundColor(.yellow)
                        .font(.subheadline)
                }
            }
            if let label = c.content {
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

struct CMeter: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var displayed = false
    var fg: Color { c.resolvedColor(palette: palette) }
    var val: Double { min(1, max(0, c.value ?? 0)) }
    var size: Double { c.minHeight ?? 120 }
    var body: some View {
        ZStack {
            Circle().stroke(fg.opacity(0.15), lineWidth: 12)
            Circle()
                .trim(from: 0, to: displayed ? val : 0)
                .stroke(fg, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0), value: displayed)
            VStack(spacing: 2) {
                Text("\(Int(val * 100))%").font(.title2.weight(.bold))
                if let label = c.content {
                    Text(label).font(.caption.weight(.medium)).foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { displayed = true }
    }
}

struct CAvatar: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    var fg: Color { c.resolvedColor(palette: palette) }
    var size: Double {
        switch c.style {
        case "display": return 80
        case "title":   return 56
        case "heading": return 40
        default:        return 32
        }
    }
    var body: some View {
        ZStack {
            Circle().fill(fg.opacity(0.15))
            if let content = c.content, !content.isEmpty {
                if content.unicodeScalars.first?.properties.isEmojiPresentation == true {
                    Text(content).font(.system(size: size * 0.5))
                } else {
                    Text(initials(from: content))
                        .font(.system(size: size * 0.35, weight: .semibold))
                        .foregroundColor(fg)
                }
            } else if let icon = c.icon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(fg)
            }
        }
        .frame(width: size, height: size)
    }

    func initials(from name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }
}

struct CTable: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    var items: [LeafItem] { c.items ?? [] }

    func itemColor(_ item: LeafItem) -> Color {
        switch item.color {
        case "accent":  return palette.accent
        case "success": return palette.success
        case "danger":  return palette.danger
        case "warning": return palette.warning
        default:        return palette.accent
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .foregroundColor(itemColor(item))
                            .frame(width: 28)
                    }
                    Text(item.label).font(.subheadline)
                    Spacer()
                    if let val = item.value {
                        Text(val).font(.subheadline).foregroundColor(.secondary)
                    } else if let sub = item.subtitle {
                        Text(sub).font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)
                if item.id != items.last?.id {
                    Divider().padding(.leading, item.icon != nil ? 52 : 0)
                }
            }
        }
    }
}

// MARK: - Layout Containers

struct CHStack: View {
    let c: Component
    var body: some View {
        HStack(alignment: .center, spacing: c.spacing ?? 10) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                if c.style == "split" {
                    ComponentView(c: child)
                        .frame(maxWidth: .infinity, alignment: child.resolvedAlignment)
                } else {
                    ComponentView(c: child)
                }
            }
        }
    }
}

struct CVStack: View {
    let c: Component
    var body: some View {
        VStack(alignment: c.resolvedHAlign, spacing: c.spacing ?? 6) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                ComponentView(c: child)
            }
        }
        .frame(maxWidth: .infinity, alignment: .init(horizontal: c.resolvedHAlign, vertical: .center))
    }
}

struct CZStack: View {
    let c: Component
    var resolvedAlignment: Alignment {
        switch c.alignment {
        case "leading":  return .leading
        case "trailing": return .trailing
        default:         return .center
        }
    }
    var body: some View {
        ZStack(alignment: resolvedAlignment) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                ComponentView(c: child)
            }
        }
    }
}

struct CGrid: View {
    let c: Component

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: c.spacing ?? 10), count: c.columns ?? 2)
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: c.itemWidth ?? 140), spacing: c.spacing ?? 10)]
    }

    var body: some View {
        if c.style == "editorial", let first = c.kids.first {
            VStack(alignment: .leading, spacing: c.spacing ?? 10) {
                ComponentView(c: first)
                if c.kids.count > 1 {
                    LazyVGrid(columns: columns, spacing: c.spacing ?? 10) {
                        ForEach(Array(c.kids.dropFirst().enumerated()), id: \.offset) { _, child in
                            ComponentView(c: child)
                        }
                    }
                }
            }
        } else {
            LazyVGrid(
                columns: c.style == "adaptive" || c.itemWidth != nil ? adaptiveColumns : columns,
                spacing: c.spacing ?? 10
            ) {
                ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                    ComponentView(c: child)
                }
            }
        }
    }
}

struct CHScroll: View {
    let c: Component
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: c.spacing ?? 12) {
                ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                    ComponentView(c: child)
                        .frame(width: c.itemWidth ?? 140)
                }
            }
        }
    }
}

struct CCard: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    var radius: Double { c.cornerRadius ?? 14 }
    var body: some View {
        VStack(alignment: c.resolvedHAlign, spacing: c.spacing ?? 8) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                ComponentView(c: child)
            }
        }
        .frame(maxWidth: .infinity,
               alignment: .init(horizontal: c.resolvedHAlign, vertical: .center))
        .padding(c.padding ?? 14)
        .background(surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(borderOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }

    private var tint: Color {
        if c.color == nil || c.color == "primary" { return palette.accent }
        return c.resolvedColor(palette: palette)
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        switch c.style {
        case "glass":
            shape.fill(.ultraThinMaterial)
        case "poster":
            shape.fill(
                LinearGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.30 : 0.22),
                        Color.systemBg.opacity(colorScheme == .dark ? 0.18 : 0.92),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case "outline":
            shape.fill(Color.clear)
        case "accent":
            shape.fill(
                LinearGradient(
                    colors: [tint.opacity(0.22), tint.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case "plain":
            shape.fill(Color.clear)
        default:
            shape.fill(c.resolvedBg(palette: palette))
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(borderColor, lineWidth: hasBorder ? 1.5 : 0)
    }

    private var borderColor: Color {
        if c.border != nil { return c.resolvedBorder(palette: palette) }
        switch c.style {
        case "glass":
            return tint.opacity(0.18)
        case "poster":
            return tint.opacity(0.32)
        case "outline":
            return tint.opacity(0.35)
        case "accent":
            return tint.opacity(0.18)
        default:
            return .clear
        }
    }

    private var hasBorder: Bool {
        c.border != nil || ["glass", "poster", "outline", "accent"].contains(c.style ?? "")
    }

    private var shadowColor: Color {
        if shadowRadius == 0 { return .clear }
        switch c.style {
        case "poster", "accent":
            return tint.opacity(0.12)
        default:
            return .black.opacity(0.08)
        }
    }

    private var shadowRadius: Double {
        if let shadow = c.shadow { return shadow }
        switch c.style {
        case "glass":
            return 6
        case "poster", "accent":
            return 10
        default:
            return 0
        }
    }
}
