# Component Audit

## Goal

Make Flash feel less like a broad demo renderer and more like an authored consumer product system: stranger, warmer, more specific, and more recognizable at a glance.

## Snapshot

- The renderer currently supports `70` component cases in [flashapp/Rendering/ComponentView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ComponentView.swift:5).
- The built-in demos plus bundled samples exercise only `26` unique component types, and the usage is concentrated in `text`, `spacer`, `card`, `checklist`, `pager`, and a few social/media blocks in [flashapp/Demo/DemoCatalog.swift](/Users/petekeating/Desktop/flashapp/flashapp/Demo/DemoCatalog.swift:16) and [flashapp/Demo/SampleApps.json](/Users/petekeating/Desktop/flashapp/flashapp/Demo/SampleApps.json:1).
- The system already contains one more opinionated visual experiment, the fluted photo header in [flashapp/Support/FlutedGlassHeader.swift](/Users/petekeating/Desktop/flashapp/flashapp/Support/FlutedGlassHeader.swift:35), but it is not currently wired into any app surface.

## What’s Working

- The component surface is broad. Flash can already render layout, media, social, utility, and flow primitives from one recursive JSON tree.
- The micro-app model is flexible enough to support more expressive composition without a rewrite.
- The app already has a lightweight “brand per app” concept through accent color.
- A few pieces already point toward a more playful direction: `swipe`, `story`, `confetti`, `wizard`, and the unused fluted header.

## Main Findings

### 1. Breadth is outpacing identity

The renderer is wide, but the visual language is narrow. Most components resolve into the same soft-gray surface, 10 to 16 point radius, accent tint, and default SF/SwiftUI typography.

Relevant files:

- [flashapp/Rendering/ComponentView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ComponentView.swift:116)
- [flashapp/Rendering/StructureComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/StructureComponents.swift:75)
- [flashapp/Rendering/InteractiveViews.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/InteractiveViews.swift:269)
- [flashapp/Rendering/SocialComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/SocialComponents.swift:202)

Effect:

- Flash feels capable, but not memorable.
- Different app ideas collapse into the same visual cadence.

### 2. The theme system is too small to create personality

`SkinPalette` only carries `accent`, `success`, `danger`, and `warning` in [flashapp/Support/MicroAppSkin.swift](/Users/petekeating/Desktop/flashapp/flashapp/Support/MicroAppSkin.swift:5). `Component.resolvedBg` only supports `tinted`, `tertiary`, `elevated`, `none`, or the default secondary background in [flashapp/Models/Models.swift](/Users/petekeating/Desktop/flashapp/flashapp/Models/Models.swift:167).

Effect:

- You can tint an app, but you cannot really theme it.
- There is no schema support for gradients, surface recipes, texture, mood, contrast level, border style, or motion identity.

### 3. Consumer surfaces are still rendered like utility software

The top-level shell is intentionally calm, but today it is calm in a generic way:

- Home is a plain list with a black capsule CTA in [flashapp/Screens/ContentView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Screens/ContentView.swift:22).
- Create is a light form sheet with suggestions and a bottom composer in [flashapp/Screens/CreateView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Screens/CreateView.swift:90).
- Onboarding is clean but extremely standard in [flashapp/Screens/OnboardingView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Screens/OnboardingView.swift:53).
- Micro-app detail wraps everything in the same lifted white card in [flashapp/Screens/MicroAppView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Screens/MicroAppView.swift:33).

Effect:

- The product shell does not sell the idea that these are playful, shareable, social micro-apps.
- Even the most expressive generated app starts inside a restrained system frame.

### 4. Many components are presentational rather than authored experiences

Several components look fine but do not carry much behavioral or emotional specificity.

Examples:

- `CCTA` and `CFloatingButton` are visually strong but use empty actions in [flashapp/Rendering/ActionComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ActionComponents.swift:9).
- `CReactionBar` is also a no-op shell in [flashapp/Rendering/SocialComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/SocialComponents.swift:97).
- Inputs/selects/date pickers all land on near-identical field styling in [flashapp/Rendering/InteractiveViews.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/InteractiveViews.swift:267) and [flashapp/Rendering/ActionComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ActionComponents.swift:177).

Effect:

- The set reads like a component inventory rather than a stable of signature product patterns.

### 5. The demos under-sell the system

The demo set is better at proving render coverage than proving taste. Even good concepts like `Vibe Decoder` and `Pip & the Moon` are still composed mostly from generic primitives in [flashapp/Demo/DemoCatalog.swift](/Users/petekeating/Desktop/flashapp/flashapp/Demo/DemoCatalog.swift:23).

Effect:

- New users see “many blocks” before they see “a fresh point of view.”
- The generator is likely learning from a library whose defaults are broader than they are stylish.

## Design Direction

### North Star

Flash should feel like:

- a little weird
- distinctly social
- visually authored, not just rendered
- more like a sharp consumer app team composed it from atoms than a model filled out a widget checklist

### What “Consumer-Coded” Means Here

- Bigger visual thesis per app, not just a single accent color
- More asymmetry, hierarchy, overlap, and contrast
- Primitive combinations that imply scenarios without hard-coding a bespoke component for each one
- Surfaces with mood: poster, sticker, scrapbook, nightlife, diary, itinerary, clubhouse
- More media-forward and social-first defaults

## Plan

### Phase 1: Expand layout grammar

Priority: highest

The current system needs more compositional moves so a strong model can build fresher layouts from the same parts.

Recommended additions:

- Better split layouts for paired content
- Uneven or featured grids
- Layered `zstack` patterns with overlap
- More full-bleed and framed media treatments
- Better support for anchored callouts, stickers, and captions
- More deliberate rail and collage behavior for image-heavy prompts

Implementation targets:

- Expand primitive layout fields in [flashapp/Models/Models.swift](/Users/petekeating/Desktop/flashapp/flashapp/Models/Models.swift:61).
- Apply transform/layout modifiers consistently in [flashapp/Support/Helpers.swift](/Users/petekeating/Desktop/flashapp/flashapp/Support/Helpers.swift:104).
- Upgrade stack, grid, and card composition behavior in [flashapp/Rendering/ComponentView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ComponentView.swift:422).

### Phase 2: Expand style atoms

Priority: highest

The model also needs a richer style vocabulary so primitives do not all collapse into the same safe treatment.

Recommended additions:

- Stronger text modes such as hero, kicker, quote, and stat
- More surface recipes for `card`
- More field treatments for `input`, `select`, and `date`
- More media framing styles for `image` and `gallery`
- Better badge and button variants for sticker, outline, pill, and solid moments

Implementation targets:

- Expand text, color, and background resolution in [flashapp/Models/Models.swift](/Users/petekeating/Desktop/flashapp/flashapp/Models/Models.swift:168).
- Add richer display and container variants in [flashapp/Rendering/ComponentView.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ComponentView.swift:84).
- Upgrade media treatments in [flashapp/Rendering/MediaComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/MediaComponents.swift:18).
- Upgrade field styling in [flashapp/Rendering/InteractiveViews.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/InteractiveViews.swift:269) and [flashapp/Rendering/ActionComponents.swift](/Users/petekeating/Desktop/flashapp/flashapp/Rendering/ActionComponents.swift:177).

### Phase 3: Rebuild demos as composition recipes

Priority: high

The demos should teach the model how to compose primitives into recognizably consumer layouts.

Recommended recipe types:

- party board with sticker badge, hero text, timer, and split row
- crush decoder with poster card, outline inputs, and bold result framing
- travel escape board with map plus collage gallery
- scrapbook-style photo dump with a featured image and supporting tiles
- editorial product or fandom board with one featured tile and support cards

Target:

- Each flagship demo should show one strong layout idea.
- Demos should feel like taste references, not coverage tests.
- The same primitives should visibly support multiple vibes.

### Phase 4: Tune generation prompts around primitives

Priority: high

The model should be explicitly pushed toward composition, not bespoke component invention.

Recommended changes:

- Update the generation system prompt to emphasize novelty from layout, hierarchy, surface treatment, and media framing
- Document the new primitive vocabulary in the schema reference
- Add a prompt-refinement pass that rewrites the user’s loose idea into a cleaner build brief for the generator
- Teach the prompt refiner to ask for one dominant layout move instead of feature sprawl

Implementation targets:

- Update generation, patch, and query prompt instructions in [flashapp/Services/ClaudeAPI.swift](/Users/petekeating/Desktop/flashapp/flashapp/Services/ClaudeAPI.swift:265).
- Add the prompt-refinement model handoff in [flashapp/Services/ClaudeAPI.swift](/Users/petekeating/Desktop/flashapp/flashapp/Services/ClaudeAPI.swift:13).

### Phase 5: Make the product shell feel more like the output

Priority: medium

The shell should stop underselling the generated apps.

Recommended changes:

- Home should preview apps like a gallery, not a plain utility list
- Create suggestions should read like strong consumer concepts
- Onboarding and detail views should better reflect the product’s expressive direction

## Suggested Execution Order

### Sprint 1

- Expand layout grammar
- Add stronger style atoms for text, card, badge, button, image, and gallery
- Update the system prompt and schema reference

### Sprint 2

- Upgrade demos so they teach composition recipes
- Add more taste-forward prompt suggestions in the create flow
- Tune generator behavior with a prompt-refinement pass

### Sprint 3

- Rework the shell so Flash itself feels less neutral
- Backfill more demos only when they teach a genuinely new layout idea

## Guardrails

- Do not solve this by exploding the component catalog.
- Do not let every prompt turn into a dashboard.
- Preserve the clean JSON-driven architecture; add expressiveness on top of it.
- Prefer 1 strong composition move over 5 weak features.
- Use demos and prompts to teach taste, not just schema breadth.

## Success Criteria

- A strong model can produce materially different layouts from the same primitive set.
- Two different app ideas no longer collapse into the same white-card treatment.
- Demos feel like composition references, not a component inventory.
- The system prompt clearly rewards hierarchy, asymmetry, overlap, and stronger surface choices.
