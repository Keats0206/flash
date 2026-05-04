import Foundation

// MARK: - Image context (Claude vision)

/// JPEG or PNG payload for the Messages API `image` content blocks.
struct ImageContextAttachment: Sendable {
    let data: Data
    let mediaType: String
}

// MARK: - Public API

func generateMicroApp(
    prompt: String,
    imageContext: [ImageContextAttachment] = [],
    locationContext: String? = nil,
    calendarContext: String? = nil,
    onTextDelta: (@Sendable (String) async -> Void)? = nil,
    onProgress: (@Sendable (String) async -> Void)? = nil
) async throws -> MicroApp {
    let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    let baseQuery = trimmed.isEmpty && !imageContext.isEmpty
        ? "Design a micro-app informed by the attached reference image(s)."
        : trimmed

    var contextLines: [String] = []
    if let loc = locationContext { contextLines.append("User location: \(loc)") }
    if let cal = calendarContext { contextLines.append(cal) }
    let fallbackQuery = (contextLines + [baseQuery])
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n\n")

    let queryForModel: String
    if !trimmed.isEmpty {
        if let onProgress { await onProgress("Sharpening the concept…") }
        do {
            queryForModel = try await refineBuildPrompt(
                rawPrompt: trimmed,
                locationContext: locationContext,
                calendarContext: calendarContext,
                hasImageContext: !imageContext.isEmpty
            )
        } catch {
            queryForModel = fallbackQuery
        }
    } else {
        queryForModel = fallbackQuery
    }

    let text = try await callClaude(
        system: generateSystemPrompt,
        userText: queryForModel,
        imageContext: imageContext,
        onTextDelta: onTextDelta,
        onProgress: onProgress
    )
    if let onProgress { await onProgress("Parsing layout JSON…") }
    let decoded = try decodeMicroApp(from: text)
    if let onProgress { await onProgress("Assembling micro-app…") }
    let built = MicroApp(
        id: decoded.id, title: decoded.title, icon: decoded.icon,
        accent: decoded.accent, body: decoded.body,
        prompt: trimmed.isEmpty ? nil : trimmed
    ).normalized()
    let (validated, _) = FlashValidator.validateAndRepair(app: built)
    return validated
}

func queryComponents(prompt: String) async throws -> [Component] {
    let text = try await callClaude(
        system: querySystemPrompt,
        userText: prompt,
        imageContext: [],
        onProgress: nil
    )
    let components = try decodeComponents(from: text)
    return FlashValidator.validateAndRepair(components: components).0
}

private func refineBuildPrompt(
    rawPrompt: String,
    locationContext: String?,
    calendarContext: String?,
    hasImageContext: Bool
) async throws -> String {
    var parts = ["User idea:\n\(rawPrompt)"]
    if let locationContext, !locationContext.isEmpty {
        parts.append("Context:\n\(locationContext)")
    }
    if let calendarContext, !calendarContext.isEmpty {
        parts.append("Calendar context:\n\(calendarContext)")
    }
    if hasImageContext {
        parts.append("Reference image(s) will also be attached to the next model call. Rewrite the prompt so the generator knows to use them for mood, subject, text-in-frame, and composition cues when relevant.")
    }

    let rewritten = try await callClaude(
        system: promptRefinementSystemPrompt,
        userText: parts.joined(separator: "\n\n"),
        imageContext: [],
        onProgress: nil,
        model: Config.promptRefinementModel,
        maxTokens: 700
    )
    return rewritten.trimmingCharacters(in: .whitespacesAndNewlines)
}

func patchMicroApp(
    current: MicroApp,
    instruction: String,
    imageContext: [ImageContextAttachment] = [],
    onTextDelta: (@Sendable (String) async -> Void)? = nil,
    onProgress: (@Sendable (String) async -> Void)? = nil
) async throws -> MicroApp {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let currentJSON = String(data: (try? encoder.encode(current)) ?? Data(), encoding: .utf8) ?? "{}"
    let trimmedInstruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
    let effectiveInstruction: String
    if trimmedInstruction.isEmpty, !imageContext.isEmpty {
        effectiveInstruction = "Update the micro-app using the attached reference image(s) for colors, layout cues, text to mirror, and overall intent."
    } else if trimmedInstruction.isEmpty {
        effectiveInstruction = "(No edit instruction provided.)"
    } else {
        effectiveInstruction = trimmedInstruction
    }
    let imageNote = imageContext.isEmpty
        ? ""
        : "\n\nThe user attached \(imageContext.count) reference image(s) — use them together with the instruction."
    let userMessage = "Current app JSON:\n\(currentJSON)\n\nEdit instruction: \(effectiveInstruction)\(imageNote)"
    let text = try await callClaude(
        system: patchSystemPrompt,
        userText: userMessage,
        imageContext: imageContext,
        onTextDelta: onTextDelta,
        onProgress: onProgress
    )
    if let onProgress { await onProgress("Applying changes to your app…") }
    let updated = try decodePatchedMicroApp(from: text, current: current)
    let merged = MicroApp(
        id: updated.id, title: updated.title, icon: updated.icon,
        accent: updated.accent, body: updated.body,
        prompt: current.prompt
    ).normalized()
    return FlashValidator.validateAndRepair(app: merged).0
}

// MARK: - Errors

enum GenerationError: LocalizedError {
    case apiError(String)
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return msg
        case .emptyResponse:     return "No response from Claude. Try again."
        case .parseError:        return "Couldn't parse the layout. Try rephrasing."
        }
    }
}

// MARK: - Shared network call

private func callClaude(
    system: String,
    userText: String,
    imageContext: [ImageContextAttachment],
    onTextDelta: (@Sendable (String) async -> Void)? = nil,
    onProgress: (@Sendable (String) async -> Void)? = nil,
    model: String = Config.anthropicModel,
    maxTokens: Int = 4096
) async throws -> String {
    let url = URL(string: "\(Config.supabaseURL)/functions/v1/claude-proxy")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
    req.setValue("Bearer \(Keychain.read(key: "supabase.accessToken") ?? "")", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "content-type")

    let bodyText: String
    if imageContext.isEmpty {
        bodyText = userText
    } else {
        let hint =
            "\n\n(Attached image(s) are visual context — use colors, subjects, text in frame, and composition when relevant.)"
        bodyText = userText + hint
    }

    var userContent: [[String: Any]] = [["type": "text", "text": bodyText]]
    for img in imageContext {
        let source: [String: Any] = [
            "type": "base64",
            "media_type": img.mediaType,
            "data": img.data.base64EncodedString(),
        ]
        userContent.append(["type": "image", "source": source])
    }

    let requestBody: [String: Any] = [
        "model": model,
        "max_tokens": maxTokens,
        "system": system,
        "messages": [["role": "user", "content": userContent]],
        "stream": onTextDelta != nil,
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    if let onProgress { await onProgress("Sending to Claude…") }
    if let onTextDelta {
        let (bytes, response) = try await URLSession.shared.bytes(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GenerationError.apiError("API error \(http.statusCode)")
        }
        if let onProgress { await onProgress("Streaming layout…") }
        let text = try await collectClaudeStream(from: bytes.lines, onTextDelta: onTextDelta)
        guard !text.isEmpty else { throw GenerationError.emptyResponse }
        return text
    }

    let (data, response) = try await URLSession.shared.data(for: req)
    if let onProgress { await onProgress("Receiving response…") }
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        let msg = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.error.message
            ?? "API error \(http.statusCode)"
        throw GenerationError.apiError(msg)
    }

    let text = try JSONDecoder().decode(ClaudeMessageResponse.self, from: data)
        .content.first?.text ?? ""
    guard !text.isEmpty else { throw GenerationError.emptyResponse }
    if let onProgress { await onProgress("Extracting JSON from reply…") }
    return text
}

private func collectClaudeStream<S: AsyncSequence>(
    from lines: S,
    onTextDelta: @Sendable (String) async -> Void
) async throws -> String where S.Element == String {
    var text = ""
    for try await rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.hasPrefix("data:") else { continue }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
        if payload == "[DONE]" { break }
        guard let data = payload.data(using: .utf8),
              let event = try? JSONDecoder().decode(ClaudeStreamEvent.self, from: data)
        else { continue }
        if event.type == "content_block_delta",
           let delta = event.delta?.text,
           !delta.isEmpty {
            text += delta
            await onTextDelta(delta)
        }
    }
    return text
}

private func decodeComponents(from text: String) throws -> [Component] {
    do {
        return try JSONDecoder().decode([Component].self, from: extractJSON(from: text))
    } catch {
        throw GenerationError.parseError
    }
}

private func decodeMicroApp(from text: String) throws -> MicroApp {
    do {
        let payload = try JSONDecoder().decode(MicroAppPayload.self, from: extractJSON(from: text))
        return MicroApp(title: payload.title, icon: payload.icon,
                        accent: payload.accent, body: payload.body, prompt: nil)
    } catch {
        throw GenerationError.parseError
    }
}

private func decodePatchedMicroApp(from text: String, current: MicroApp) throws -> MicroApp {
    let data = extractJSON(from: text)
    if let payload = try? JSONDecoder().decode(MicroAppPatchPayload.self, from: data) {
        return mergePatch(payload, into: current)
    }
    return try decodeMicroApp(from: text)
}

private func mergePatch(_ patch: MicroAppPatchPayload, into current: MicroApp) -> MicroApp {
    let mergedBody: [Component]
    if let patchBody = patch.body {
        mergedBody = mergeComponents(current.body, with: patchBody)
    } else {
        mergedBody = current.body
    }

    return MicroApp(
        id: current.id,
        title: patch.title ?? current.title,
        icon: patch.icon ?? current.icon,
        accent: patch.accent ?? current.accent,
        body: mergedBody,
        prompt: current.prompt
    )
}

private func mergeComponents(_ current: [Component], with patch: [Component]) -> [Component] {
    var patchByID = Dictionary(uniqueKeysWithValues: patch.compactMap { component in
        component.id.map { ($0, component) }
    })

    var result: [Component] = []
    let currentIDs = Set(current.compactMap(\.id))
    let patchIDs = Set(patch.compactMap(\.id))

    for existing in current {
        guard let id = existing.id else {
            result.append(existing)
            continue
        }
        if let replacement = patchByID.removeValue(forKey: id) {
            result.append(mergeComponent(existing, with: replacement))
        } else if !patchIDs.isEmpty && !patchIDs.contains(id) {
            result.append(existing)
        }
    }

    for candidate in patch {
        if let id = candidate.id {
            if !currentIDs.contains(id), let remaining = patchByID[id] {
                result.append(remaining)
            }
        } else {
            result.append(candidate)
        }
    }

    return result
}

private func mergeComponent(_ current: Component, with patch: Component) -> Component {
    let mergedChildren: [Component]?
    if let patchChildren = patch.children {
        mergedChildren = mergeComponents(current.children ?? [], with: patchChildren)
    } else {
        mergedChildren = current.children
    }

    let mergedSteps: [WizardStep]?
    if let patchSteps = patch.steps {
        mergedSteps = patchSteps
    } else {
        mergedSteps = current.steps
    }

    return Component(
        id: patch.id ?? current.id,
        type: patch.type,
        children: mergedChildren,
        items: patch.items ?? current.items,
        content: patch.content ?? current.content,
        icon: patch.icon ?? current.icon,
        style: patch.style ?? current.style,
        weight: patch.weight ?? current.weight,
        color: patch.color ?? current.color,
        background: patch.background ?? current.background,
        alignment: patch.alignment ?? current.alignment,
        padding: patch.padding ?? current.padding,
        cornerRadius: patch.cornerRadius ?? current.cornerRadius,
        columns: patch.columns ?? current.columns,
        spacing: patch.spacing ?? current.spacing,
        itemWidth: patch.itemWidth ?? current.itemWidth,
        opacity: patch.opacity ?? current.opacity,
        rotation: patch.rotation ?? current.rotation,
        scale: patch.scale ?? current.scale,
        offsetX: patch.offsetX ?? current.offsetX,
        offsetY: patch.offsetY ?? current.offsetY,
        minWidth: patch.minWidth ?? current.minWidth,
        maxWidth: patch.maxWidth ?? current.maxWidth,
        aspectRatio: patch.aspectRatio ?? current.aspectRatio,
        zIndex: patch.zIndex ?? current.zIndex,
        value: patch.value ?? current.value,
        border: patch.border ?? current.border,
        shadow: patch.shadow ?? current.shadow,
        minHeight: patch.minHeight ?? current.minHeight,
        action: patch.action ?? current.action,
        name: patch.name ?? current.name,
        src: patch.src ?? current.src,
        subtitle: patch.subtitle ?? current.subtitle,
        urls: patch.urls ?? current.urls,
        latitude: patch.latitude ?? current.latitude,
        longitude: patch.longitude ?? current.longitude,
        duration: patch.duration ?? current.duration,
        steps: mergedSteps,
        mode: patch.mode ?? current.mode
    )
}

// MARK: - Private decodables

private struct ClaudeMessageResponse: Codable {
    struct Content: Codable { let type: String; let text: String }
    let content: [Content]
}

private struct ClaudeStreamEvent: Codable {
    struct Delta: Codable {
        let text: String?
    }

    let type: String
    let delta: Delta?
}

private struct APIErrorBody: Codable {
    struct Inner: Codable { let message: String }
    let error: Inner
}

private struct MicroAppPayload: Codable {
    let title: String
    let icon: String
    let accent: String
    let body: [Component]
}

private struct MicroAppPatchPayload: Codable {
    let title: String?
    let icon: String?
    let accent: String?
    let body: [Component]?
}

// MARK: - JSON extraction (handles accidental markdown fences)

private func extractJSON(from text: String) -> Data {
    var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("```") {
        s = s.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
    }
    return s.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) ?? Data()
}

// MARK: - Generate system prompt

private let generateSystemPrompt = """
You are a micro-app layout engine for Flash, an iOS app that renders AI-generated layouts from primitives. Given a build brief (and optional reference images), respond with ONLY a single raw JSON object: no markdown fences, no explanation, no code blocks.

When images are included, use them for subject matter, mood, color, cropping, text-in-frame, and composition cues when relevant.

Build novelty from primitives, not from inventing bespoke widgets. Prefer stronger hierarchy, smarter layout, and bolder surface treatment over adding more unrelated features.
Prefer apps that are immediately useful on iPhone: short flows, compact layouts, clear actions, and one core job.
Use shared binding keys (`name`) when multiple controls or AI steps should reference the same user input or state.
Use supported action strings instead of inventing hidden behavior.

The JSON must match this exact shape:

{
"title": "Short title (2-4 words)",
"icon": "SF Symbol name",
"accent": "#RRGGBB",
"body": [ ...components... ]
}

\(schemaReference)
"""

// MARK: - Prompt refinement

private let promptRefinementSystemPrompt = """
You rewrite a user's raw app idea into a sharp Flash build brief for another model.

Return plain text only. No markdown fences. No bullet nesting. Keep it tight.

Goals:
- preserve the user's core intent
- make the brief easier to design from
- suggest composition using existing primitives, not bespoke widgets
- keep scope lean

The rewritten brief should usually include:
- the app's core job
- the essential content or interaction
- the desired mood or tone
- 2-4 composition cues using primitive language
- a simplicity guardrail

Use composition language like:
- featured hero
- poster card
- split row
- editorial grid
- layered zstack
- sticker-like badges
- collage gallery
- compact social rail

Do not invent fake component names unless they already exist in Flash.
Do not add unrelated features.
Do not turn simple prompts into dashboards.
Keep the rewrite to roughly 6-10 short lines.
"""

// MARK: - Patch system prompt

private let patchSystemPrompt = """
You are editing an existing Flash micro-app layout.
The user will give you the current JSON and an edit instruction, and may attach reference images.

Return ONLY raw JSON.
No markdown fences, no explanation, just raw JSON.

Apply the smallest change that satisfies the instruction.
Preserve existing structure unless the instruction clearly calls for a layout change.
Prefer returning a PATCH object with only the changed fields:
{
  "title": "optional changed title",
  "icon": "optional changed icon",
  "accent": "optional changed accent",
  "body": [ ...only changed or added components... ]
}

When patching body components, preserve each component's stable "id" and return only the changed subtree when possible.
If the requested change is too broad for a patch, you may return the full app object instead.
When adding behavior, prefer supported action strings and existing binding keys over inventing new custom mechanisms.

\(schemaReference)
"""

// MARK: - Shared schema reference

private let querySystemPrompt = """
You are an AI assistant embedded in a Flash micro-app. The user submitted a query through an interactive form.

Return ONLY a raw JSON array of Component objects — no markdown fences, no wrapper object, no explanation.

Address the user's query directly. Prefer text, card, badge, hstack, vstack, grid, table, chart, progress, meter, rating, tagcloud, poll, and comment.
Keep it focused and scannable. Avoid heavy video URLs in query responses unless asked.
"""

private let schemaReference = """
──────────────────────────────────────────
COMPONENT REFERENCE
──────────────────────────────────────────

GENERIC OPTIONAL FIELDS
These may appear on many components when useful:
  "id": "stable.component.id"
  "alignment": "leading|center|trailing"
  "padding": 16
  "spacing": 10
  "cornerRadius": 14
  "background": "accent|tinted|secondary|tertiary|elevated|none"
  "border": "accent|secondary|#RRGGBB"
  "shadow": 8
  "opacity": 0.92
  "rotation": -4
  "scale": 0.98
  "offsetX": 10
  "offsetY": -6
  "minWidth": 120
  "maxWidth": 260
  "minHeight": 180
  "aspectRatio": 1.3
  "zIndex": 2

TEXT / DISPLAY ATOMS
  { "type": "text", "content": "...", "style": "hero|display|title|heading|quote|stat|body|label|caption|kicker|mono", "weight": "regular|medium|semibold|bold|black", "color": "primary|secondary|inverse|accent|success|danger|warning" }
  { "type": "badge", "content": "...", "style": "solid|outline|sticker", "color": "accent|success|danger|warning|secondary" }
  { "type": "icon", "icon": "SF Symbol", "style": "heading|label|body|caption", "color": "primary|secondary|inverse|accent|success|danger|warning" }
  { "type": "divider" }
  { "type": "spacer", "spacing": 8 }

INDICATORS
  { "type": "progress", "content": "Label", "value": 0.75, "color": "accent|success|danger|warning" }
  { "type": "meter", "content": "Label", "value": 0.75, "color": "accent", "minHeight": 120 }
  { "type": "rating", "value": 4.5, "content": "Optional label" }
  { "type": "avatar", "content": "Name or emoji", "icon": "SF Symbol optional", "style": "display|title|heading|label", "color": "accent" }

INTERACTIVE LEAVES
  { "type": "checklist", "items": [{ "id": "c1", "label": "...", "icon": "SF Symbol optional", "color": "accent|success|danger|warning" }] }
  { "type": "swipe", "items": [{ "id": "s1", "label": "...", "subtitle": "...", "emoji": "..." }] }
  { "type": "pager", "items": [{ "id": "p1", "label": "...", "subtitle": "...", "emoji": "..." }] }
  { "type": "table", "items": [{ "id": "t1", "label": "...", "value": "...", "icon": "SF Symbol optional", "color": "accent|success|danger|warning" }] }
  { "type": "tagcloud", "items": [{ "id": "g1", "label": "...", "color": "accent|success|danger|warning|secondary" }] }
  { "type": "toggle", "content": "Label", "value": 0, "name": "bindingKey optional" }
  { "type": "stepper", "content": "Label", "value": 3, "name": "bindingKey optional" }
  { "type": "input", "content": "Placeholder…", "icon": "text.cursor", "style": "outline|glass|poster", "name": "bindingKey optional" }
  { "type": "button", "content": "Label", "icon": "SF Symbol optional", "style": "solid|outline|pill", "color": "accent|success|danger|warning", "action": "url:https://... | copy:... | share_text:... | share_url:https://..." }
  { "type": "aiquery", "content": "Button label", "action": "Analyze {{fieldName}} and give feedback", "mode": "replace|append", "children": [
      { "type": "input", "content": "Placeholder…", "name": "fieldName", "style": "outline|glass|poster" }
    ]
  }

LAYOUT CONTAINERS
  { "type": "vstack", "children": [...], "spacing": 10, "alignment": "leading|center|trailing" }
  { "type": "hstack", "children": [...], "spacing": 12, "style": "split" }
  { "type": "zstack", "children": [...], "alignment": "leading|center|trailing" }
  { "type": "grid", "children": [...], "columns": 2, "spacing": 10, "style": "adaptive|editorial", "itemWidth": 140 }
  { "type": "hscroll", "children": [...], "spacing": 12, "itemWidth": 160 }
  { "type": "card", "children": [...], "style": "glass|poster|outline|accent|plain", "background": "accent|tinted|secondary|tertiary|elevated|none", "alignment": "leading|center|trailing", "padding": 16, "cornerRadius": 14, "shadow": 8, "border": "accent|secondary|#RRGGBB" }

MEDIA & DATA
  { "type": "image", "src": "https://...", "style": "bleed|poster|polaroid", "minHeight": 180, "cornerRadius": 12, "icon": "optional SF Symbol for placeholder" }
  { "type": "video", "src": "https://...mp4", "minHeight": 200 }
  { "type": "audio", "src": "https://...mp3 or m4a", "content": "Title", "subtitle": "Artist optional" }
  { "type": "gallery", "style": "collage", "urls": ["https://..."] }
  { "type": "map", "content": "Pin label", "latitude": 37.77, "longitude": -122.42, "value": 0.05 }
    value = optional map zoom span (~0.01–2.0)
  { "type": "chart", "content": "Title", "style": "bar|line", "items": [{ "id": "jan", "label": "Jan", "value": "12" }], "minHeight": 140 }
  { "type": "calendar", "content": "Section title optional" }

STRUCTURE
  { "type": "section", "content": "Header", "children": [...] }
  { "type": "list", "children": [...], "minHeight": 200 }
  { "type": "tabs", "items": [{ "id": "t1", "label": "Home" }], "children": [ ...one root component per tab... ] }
  { "type": "accordion", "children": [ { "type": "section", "content": "Row title", "children": [...] } ] }
  { "type": "sheet", "content": "Open sheet", "subtitle": "Sheet nav title", "children": [...] }
  { "type": "modal", "content": "Open", "subtitle": "Modal title", "children": [...] }
  { "type": "nav", "items": [{ "id": "n1", "label": "For You", "icon": "star.fill" }] }

WIZARD / FLOWS
  { "type": "wizard", "padding": 0, "steps": [
      { "id": "step_collect", "title": "Pick options", "children": [ ... ] },
      { "id": "step_review", "title": "Review", "children": [ ... ] },
      { "id": "step_generate", "title": "Result", "children": [ { "type": "aiquery", ... } ] }
    ]
  }
  Each step object uses "children" OR "body". Include stable string "id" per step.

SOCIAL / CONSUMER
  { "type": "comment", "content": "Author", "subtitle": "Comment text...", "icon": "person.crop.circle optional" }
  { "type": "thread", "children": [ nested thread nodes with content/subtitle/items ] }
  { "type": "reaction", "items": [{ "id": "r1", "label": "👍", "emoji": "👍" }] OR omit items for defaults }
  { "type": "share", "content": "Share", "src": "https://optional-url" }
  { "type": "vote", "content": "Optional caption" }
  { "type": "poll", "content": "Question?", "items": [{ "id": "p1", "label": "Option A" }] }
  { "type": "profile", "content": "Name", "subtitle": "Bio", "src": "https://avatar.jpg", "icon": "SF Symbol fallback", "children": [stats...] }
  { "type": "presence", "content": "Online", "subtitle": "2m ago", "value": 1 }

ACTIONS & STATE
  Supported action strings for tappable components:
    "url:https://example.com"
    "open:https://example.com"
    "copy:Text to copy"
    "share_text:Text to share"
    "share_url:https://example.com"
  { "type": "cta", "content": "Get started", "icon": "arrow.right", "subtitle": "optional secondary text", "action": "url:https://..." }
  { "type": "fab", "icon": "plus", "subtitle": "optional caption", "action": "copy:..." }
  { "type": "timer", "content": "Label", "duration": 120, OR "value": 120 }
  { "type": "counter", "content": "Guests", "value": 0 }
  { "type": "progress_ring", "value": 0.72, "content": "Label", "minHeight": 100 }
  { "type": "form", "children": [inputs, toggles, ...], "minHeight": 220 }
  { "type": "select", "content": "Field label", "style": "outline|glass", "name": "bindingKey optional", "items": [{ "id": "a", "label": "A" }] }
  { "type": "date", "content": "Pick date", "style": "outline|glass", "name": "bindingKey optional" }
  { "type": "upload", "content": "Upload", "subtitle": "hint", "icon": "arrow.up.doc" }

DELIGHT
  { "type": "confetti", "minHeight": 120 }
  { "type": "tooltip", "content": "Label", "subtitle": "Popover body", "icon": "questionmark.circle" }
  { "type": "badge_stack", "items": [{ "id": "b1", "label": "AB", "emoji": "optional" }], "content": "+3 friends" }
  { "type": "story", "items": [{ "id": "s1", "label": "Title", "subtitle": "sub", "mediaURL": "https://..." }], "minHeight": 320 }

──────────────────────────────────────────
DESIGN RULES
──────────────────────────────────────────

accent MUST be exactly one of these hex strings unless the user explicitly requests a custom color:
#4A8EDB, #FF3B30, #F4B95E, #E56A9A, #8FAFBE, #B6DE6F, #EFC1C9, #F5E51B

Build from a small number of atoms with a clear visual thesis.

Prefer one dominant layout move, such as:
- hero text inside a poster or accent card
- editorial grid with one featured item and supporting tiles
- split hstack for paired content
- layered zstack using offset, rotation, and zIndex for stickers or callouts
- collage gallery for photo-heavy prompts

Use stronger hierarchy before adding more features.

Good novelty comes from composition:
- text scale contrast
- surface recipe changes
- asymmetry
- overlap
- tighter or looser density
- media framing

Avoid bland repetition of text + spacer + card + checklist unless it truly fits.

Prefer 1 focused interaction over many weak ones.

Do not combine unrelated features into one layout.

Use wizard only for true multi-step flows.

Use aiquery when the app needs user input plus AI output.
For tappable behavior, only use the supported `action` string formats listed above.
Prefer `copy:` or `share_text:` for shareable text moments, and `url:` / `open:` for outbound links.
Prefer shared `name` keys when multiple fields or controls should work together as one flow.

Media URLs should be https and publicly reachable when possible.

Inputs inside aiquery must have a "name" field matching a {{name}} placeholder in the parent action string.

icon must be a valid SF Symbol name.

All item ids must be unique strings.

Do NOT include an "id" field at the top level of the JSON.
Do include stable component "id" fields inside body components when generating or patching.
Reuse the same component "id" when updating an existing subtree.

──────────────────────────────────────────
COMPLEXITY RULES
──────────────────────────────────────────

Default to minimal UI unless the user explicitly asks for a full app.

Simple prompt:
- usually 1 hero or 1 card
- maybe 1 support block

Moderate prompt:
- 1 section or 1 featured grid
- 1–2 cards

Complex prompt:
- only add more structure if the request truly demands it

Bias toward under-building rather than over-building.

The UI should feel like one continuous task, not a dashboard.
"""
