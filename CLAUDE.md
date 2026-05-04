# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Flash** — an iOS/iPadOS SwiftUI app that renders AI-generated micro-apps from a composable JSON schema. Users describe an idea; Claude generates a layout tree that renders natively. Bundle ID `unless.flashapp`, targeting iOS 18.5+, Swift 5.0.

## Build & Run

Open `flashapp.xcodeproj` in Xcode and run on a simulator or device.

```bash
xcodebuild -project flashapp.xcodeproj -scheme flashapp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

All code lives in `flashapp/ContentView.swift`. Two screens driven by `NavigationStack`:

**`ContentView`** (home gallery) → tap `AppCard` → **`MicroAppView`** (renderer)

---

### Data model — the component tree

`MicroApp` has a `body: [Component]` array. Every layout is a recursive tree of `Component` nodes — no fixed section types.

```
MicroApp       title, icon (SF Symbol), accent (hex), body: [Component]
Component      type + optional fields (see below)
LeafItem       id, label, subtitle?, value?, emoji?   — used by interactive leaves only
```

**Component `type` values and the fields they use:**

| type | key fields | renders as |
|------|-----------|------------|
| `text` | content, style, color, weight | styled text |
| `badge` | content, color | pill label |
| `icon` | icon (SF Symbol), color, style | SF Symbol |
| `divider` | — | `Divider()` |
| `spacer` | spacing (minLength) | `Spacer()` |
| `hstack` | children, spacing | horizontal stack |
| `vstack` | children, spacing, alignment | vertical stack |
| `grid` | children, columns, spacing | `LazyVGrid` |
| `hscroll` | children, spacing, itemWidth | horizontal scroll |
| `card` | children, background, padding, cornerRadius, alignment | rounded container |
| `checklist` | items | tappable checkboxes |
| `swipe` | items | Tinder-style swipe deck |
| `pager` | items | `TabView` page carousel |

**`style`** values: `display` `title` `heading` `label` `body` `caption` `mono`  
**`color`** values: `primary` `secondary` `accent` `success` `danger` `warning`  
**`background`** values: `tinted` (accent@10%) `secondary` `tertiary` `elevated` `none`

### Rendering

`ComponentView` is a recursive dispatcher — it reads `c.type` and returns the matching view. Layout containers (`CHStack`, `CVStack`, `CGrid`, `CHScroll`, `CCard`) each iterate `c.kids` and render children as `ComponentView`. Interactive leaves (`ChecklistView`, `SwipeView`, `PagerView`) are terminal — they take `[LeafItem]` and own their own state.

### Adding a new component type

1. Add a `case "newtype"` in `ComponentView.body`
2. Create a new `struct CNewType: View` that reads from the `Component` fields it needs
3. Add any new fields to `Component` as `let xxx: Type?`

### Cross-platform guards

All UIKit references are behind `#if os(iOS)` or in the `private Color` extension that has `#if os(iOS)` / `#else` branches. The `.toolbar(.hidden, for: .navigationBar)` and `.tabViewStyle(.page(...))` calls are wrapped in `hideNavBar()` and `pageStyle()` View extensions for the same reason.

## Next Steps

- Wire up Claude API: POST to `https://api.anthropic.com/v1/messages`, system prompt instructs Claude to return only JSON matching the `Component` tree schema, decode into `MicroApp`.
- Add prompt input screen + generating/loading state.
- Persist generated apps (SwiftData or UserDefaults).
- Share: encode `MicroApp.body` as JSON, base64 into a deep link or short URL.

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
