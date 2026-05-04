import Foundation

/// Built-in demos (fixed UUIDs — not saved to disk). Add variants here anytime.
enum DemoCatalog {
    private static let idVibe = UUID(uuidString: "A0000000-0000-4000-A000-000000000001")!
    private static let idPulse = UUID(uuidString: "A0000000-0000-4000-A000-000000000002")!
    private static let idAway = UUID(uuidString: "A0000000-0000-4000-A000-000000000003")!
    private static let idTour = UUID(uuidString: "A0000000-0000-4000-A000-000000000004")!
    private static let idStorybook = UUID(uuidString: "A0000000-0000-4000-A000-000000000005")!
    private static let idStepFlow = UUID(uuidString: "A0000000-0000-4000-A000-000000000006")!

    static func isDemo(id: UUID) -> Bool {
        apps.contains(where: { $0.id == id })
    }

    /// Inline demos plus any entries from `SampleApps.json` in the bundle.
    static let apps: [MicroApp] =
        dedupeApps(
            [vibeDecoder, socialPulse, tripAwayDay, flashTour, moonlightStory, stepFlowDemo]
                + SampleApps.loadBundled()
        )
}

private extension DemoCatalog {
    static func dedupeApps(_ apps: [MicroApp]) -> [MicroApp] {
        var seen = Set<UUID>()
        var deduped: [MicroApp] = []

        for app in apps {
            if seen.insert(app.id).inserted {
                deduped.append(app)
            } else {
                #if DEBUG
                print("DemoCatalog: duplicate demo app id dropped for \(app.title) (\(app.id))")
                #endif
            }
        }

        return deduped
    }

    static var vibeDecoder: MicroApp {
        MicroApp(
            id: idVibe,
            title: "Vibe Decoder",
            icon: "theatermasks.fill",
            accent: "#E56A9A",
            body: [
                Component(type: "vstack",
                          children: [
                            Component(type: "badge", content: "GROUP CHAT FORENSICS",
                                      style: "sticker", color: "accent",
                                      rotation: -3, maxWidth: 180),
                            Component(type: "text", content: "Vibe Decoder",
                                      style: "hero", weight: "black"),
                            Component(type: "text",
                                      content: "Paste convo text or describe what you heard. Get moods, translation, replies — sharable takeaway included.",
                                      style: "body", color: "secondary")
                          ],
                          alignment: "leading", spacing: 8),
                Component(type: "spacer", spacing: 8),
                Component(type: "card",
                          children: [
                            Component(type: "aiquery",
                                      children: [
                                        Component(type: "input",
                                                  content: "Paste text or describe convo/screenshot vibe…",
                                                  icon: "text.quote", style: "outline",
                                                  name: "paste"),
                                        Component(type: "input",
                                                  content: "Optional: tone you want or relationship.",
                                                  icon: "sparkles", style: "outline",
                                                  name: "context")
                                      ],
                                      content: "Decode the vibe",
                                      action: """
                                      User is decoding people, places, or texts.\n\
                                      INPUT:\n{{paste}}\n\
                                      CONTEXT:\n{{context}}\n\
                                      Respond with ONLY a JSON array of Flash Component objects.\n\
                                      Include: (1) section \"Emotional breakdown\" using tags or bullets, (2) card \"What they actually mean\", (3) card with three replies labeled Flirty / Assertive / Funny as short quoted lines, (4) optional share-friendly one-liner mentioning 👀 Keep under 22 components total.
                                      """)
                          ],
                          style: "poster",
                          padding: 14, cornerRadius: 20, shadow: 10)
            ],
            prompt: "Paste convo text and decode the vibe — moods, replies, and a shareable takeaway"
        )
    }

    static var socialPulse: MicroApp {
        MicroApp(
            id: idPulse,
            title: "Social Pulse",
            icon: "person.3.sequence.fill",
            accent: "#4A8EDB",
            body: [
                Component(type: "text", content: "Tonight’s orbit",
                          style: "title", weight: "bold"),
                Component(type: "text",
                          content: "Demo of comment + presence + reactions + poll + share.",
                          style: "caption", color: "secondary"),
                Component(type: "spacer", spacing: 6),
                Component(type: "presence", content: "Riley · host",
                          value: 1, subtitle: "active now · 3 friends nearby"),
                Component(type: "spacer", spacing: 10),
                Component(type: "profile",
                          children: [
                            Component(type: "hstack",
                                      children: [
                                        Component(type: "badge", content: "+12%", color: "accent"),
                                        Component(type: "text", content: "Reply rate this week.",
                                                  style: "caption")
                                      ],
                                      spacing: 10)
                          ],
                          content: "Maya Cohen",
                          icon: "bolt.heart.fill",
                          subtitle: "Writes long voice notes • loves sunrise runs"),
                Component(type: "spacer", spacing: 10),
                Component(type: "comment",
                          content: "Taylor",
                          icon: "person.crop.circle.fill",
                          subtitle: "Honestly I’d rather do the meme night than brunch again 👀"),
                Component(type: "spacer", spacing: 8),
                Component(type: "reaction"),
                Component(type: "spacer", spacing: 12),
                Component(type: "poll",
                          items: [
                            LeafItem(id: "p1", label: "Lazy coffee"),
                            LeafItem(id: "p2", label: "City walk"),
                            LeafItem(id: "p3", label: "Sprint session")
                          ],
                          content: "Tomorrow’s vibe?"),
                Component(type: "spacer", spacing: 12),
                Component(type: "share",
                          content: "this is what she meant 👀",
                          icon: "square.and.arrow.up")
            ],
            prompt: "Tonight’s orbit — presence, profiles, reactions, polls, and share"
        )
    }

    static var tripAwayDay: MicroApp {
        MicroApp(
            id: idAway,
            title: "Away Day",
            icon: "airplane.departure",
            accent: "#F4B95E",
            body: [
                Component(type: "badge", content: "WEEKEND ESCAPE",
                          style: "outline", color: "accent", maxWidth: 150),
                Component(type: "text", content: "Lisbon · 72h",
                          style: "hero", weight: "black"),
                Component(type: "text",
                          content: "Map + gallery placeholders + checklist for real trips.",
                          style: "body", color: "secondary"),
                Component(type: "spacer", spacing: 10),
                Component(type: "map", content: "Miradouro",
                          cornerRadius: 14, value: 0.045, minHeight: 160,
                          latitude: 38.7169, longitude: -9.139),
                Component(type: "spacer", spacing: 14),
                Component(type: "gallery",
                          style: "collage",
                          minHeight: 200,
                          urls: [
                            "https://images.unsplash.com/photo-1585208798176-6dae93246618?w=800&q=80",
                            "https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800&q=80"
                          ]),
                Component(type: "spacer", spacing: 12),
                Component(type: "checklist",
                          items: [
                            LeafItem(id: "c1", label: "Tram 28 queue", icon: "tram.fill"),
                            LeafItem(id: "c2", label: "Pastéis warmup", emoji: "🥧"),
                            LeafItem(id: "c3", label: "Sunset lookout", icon: "sun.horizon.fill")
                          ]),
                Component(type: "cta",
                          content: "Share ETA",
                          icon: "arrow.right.circle.fill",
                          subtitle: "Copied vibe draft")
            ],
            prompt: "Lisbon weekend — map pins, gallery, packing checklist"
        )
    }

    static var flashTour: MicroApp {
        MicroApp(
            id: idTour,
            title: "Flash Tour",
            icon: "rectangle.stack.fill",
            accent: "#B6DE6F",
            body: [
                Component(type: "badge", content: "PRIMITIVE PLAYBOOK",
                          style: "sticker", color: "accent", rotation: -2, maxWidth: 160),
                Component(type: "text", content: "What Flash can render",
                          style: "hero", weight: "black"),
                Component(type: "text",
                          content: "Flip the pager • tick the list • skim tags.",
                          style: "caption", color: "secondary"),
                Component(type: "spacer", spacing: 8),
                Component(type: "pager",
                          items: [
                            LeafItem(id: "pg1", label: "Micro-apps", subtitle: "One JSON graph", emoji: "✨"),
                            LeafItem(id: "pg2", label: "AI edit bar", subtitle: "Remix layouts", emoji: "🪄"),
                            LeafItem(id: "pg3", label: "Share links", subtitle: "flash:// imports", emoji: "🔗")
                          ]),
                Component(type: "spacer", spacing: 12),
                Component(type: "grid",
                          children: [
                            Component(type: "card",
                                      children: [
                                        Component(type: "text", content: "Compose bigger ideas from smaller blocks.",
                                                  style: "quote"),
                                        Component(type: "tagcloud",
                                                  items: [
                                                    LeafItem(id: "g1", label: "stacks", color: "accent"),
                                                    LeafItem(id: "g2", label: "media", color: "success"),
                                                    LeafItem(id: "g3", label: "social", color: "warning"),
                                                    LeafItem(id: "g4", label: "forms", color: "secondary"),
                                                    LeafItem(id: "g5", label: "maps", color: "danger")
                                                  ],
                                                  spacing: 10)
                                      ],
                                      style: "poster",
                                      padding: 16),
                            Component(type: "card",
                                      children: [
                                        Component(type: "text", content: "Try Vibe Decoder", style: "heading"),
                                        Component(type: "text", content: "Prompt + AI query + layered results", style: "caption", color: "secondary")
                                      ],
                                      style: "outline"),
                            Component(type: "card",
                                      children: [
                                        Component(type: "text", content: "Duplicate a demo", style: "heading"),
                                        Component(type: "text", content: "Remix layouts into your own app", style: "caption", color: "secondary")
                                      ],
                                      style: "outline"),
                            Component(type: "card",
                                      children: [
                                        Component(type: "text", content: "Create from scratch", style: "heading"),
                                        Component(type: "text", content: "Start with one idea and let the model compose it", style: "caption", color: "secondary")
                                      ],
                                      style: "outline")
                          ],
                          style: "editorial",
                          spacing: 10
                         )
            ],
            prompt: "Swipe the pager — checklist and tags showcase what Flash renders"
        )
    }

    /// TabView pager demo framed as a tiny swipeable children’s book.
    static var moonlightStory: MicroApp {
        MicroApp(
            id: idStorybook,
            title: "Pip & the Moon",
            icon: "book.pages.fill",
            accent: "#7EC8E3",
            body: [
                Component(type: "vstack",
                          children: [
                            Component(type: "text", content: "Pip & the Moon",
                                      style: "title", weight: "bold"),
                            Component(type: "text",
                                      content: "Swipe each spread like turning pages — emoji pictures, short verses below.",
                                      style: "caption", color: "secondary")
                          ],
                          alignment: "leading", spacing: 6),
                Component(type: "spacer", spacing: 10),
                Component(type: "pager",
                          items: [
                            LeafItem(id: "s1", label: "Once upon a twilight…",
                                     subtitle: "The garden folded its petals. Crickets tuned their tiny violins.",
                                     emoji: "🌙"),
                            LeafItem(id: "s2", label: "Pip peeked from the ferns",
                                     subtitle: "“Moon,” asked the smallest fox, “will you walk me home?”",
                                     emoji: "🦊"),
                            LeafItem(id: "s3", label: "The sky leaned closer",
                                     subtitle: "Stars stitched a silver ribbon along the mossy trail.",
                                     emoji: "✨"),
                            LeafItem(id: "s4", label: "The den, at last",
                                     subtitle: "Warm breath, soft thistledown, and dreams of breakfast berries.",
                                     emoji: "🏠"),
                            LeafItem(id: "s5", label: "Goodnight, reader",
                                     subtitle: "The end — or the start of your own next page.",
                                     emoji: "💤")
                          ]),
                Component(type: "spacer", spacing: 12),
                Component(type: "text",
                          content: "Tip: Flash’s pager is a native page TabView — perfect for stories, tours, and carousels.",
                          style: "caption", color: "secondary")
            ],
            prompt: "Swipe-through bedtime story book using pager spreads with emoji and verse"
        )
    }

    /// Native wizard: stepped UI with Back / Next (not separate fake cards).
    static var stepFlowDemo: MicroApp {
        MicroApp(
            id: idStepFlow,
            title: "Step Flow",
            icon: "arrow.triangle.2.circlepath",
            accent: "#8FAFBE",
            body: [
                Component(type: "text", content: "Guided flow",
                          style: "title", weight: "bold"),
                Component(type: "text",
                          content: "Flash renders one wizard step at a time — try Next and Back.",
                          style: "caption", color: "secondary"),
                Component(type: "spacer", spacing: 10),
                Component(type: "card",
                          children: [
                            Component(
                                type: "wizard",
                                padding: 0,
                                steps: [
                                    WizardStep(
                                        id: "pick",
                                        title: "Choose a vibe",
                                        children: [
                                            Component(type: "text",
                                                      content: "Tag clouds and inputs can live inside steps.",
                                                      style: "body", color: "secondary"),
                                            Component(type: "tagcloud",
                                                      items: [
                                                        LeafItem(id: "w1", label: "Focus", color: "accent"),
                                                        LeafItem(id: "w2", label: "Chill", color: "success"),
                                                        LeafItem(id: "w3", label: "Social", color: "warning")
                                                      ],
                                                      spacing: 8)
                                        ]
                                    ),
                                    WizardStep(
                                        id: "note",
                                        title: "Add a detail",
                                        children: [
                                            Component(type: "input",
                                                      content: "Optional note for the next step…",
                                                      icon: "text.alignleft",
                                                      name: "note")
                                        ]
                                    ),
                                    WizardStep(
                                        id: "done",
                                        title: "You’re set",
                                        children: [
                                            Component(type: "text",
                                                      content: "Put an aiquery on this step for a real generator, or keep it static like this demo.",
                                                      style: "body"),
                                            Component(type: "badge", content: "Wizard complete", color: "success")
                                        ]
                                    )
                                ]
                            )
                          ],
                          background: "tinted",
                          padding: 16,
                          cornerRadius: 16)
            ],
            prompt: "Three-step wizard demo — native Back / Next, no improvised cards"
        )
    }
}
