import Foundation

struct FlashValidationWarning: Identifiable {
    let id = UUID()
    let componentID: String?
    let message: String
}

enum FlashValidator {
    static func validateAndRepair(app: MicroApp) -> (MicroApp, [FlashValidationWarning]) {
        var warnings: [FlashValidationWarning] = []
        let repairedBody = repair(components: app.body, warnings: &warnings)
        let repairedAccent = Config.allowedAccentHexes.contains(app.accent.uppercased()) ? app.accent.uppercased() : Config.allowedAccentHexes.first ?? app.accent
        if repairedAccent.uppercased() != app.accent.uppercased() {
            warnings.append(.init(componentID: nil, message: "Accent color normalized to supported palette"))
        }

        let repaired = MicroApp(
            id: app.id,
            title: app.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : app.title,
            icon: app.icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "sparkles" : app.icon,
            accent: repairedAccent,
            body: repairedBody,
            prompt: app.prompt
        ).normalized()

        return (repaired, warnings)
    }

    static func validateAndRepair(components: [Component]) -> ([Component], [FlashValidationWarning]) {
        var warnings: [FlashValidationWarning] = []
        return (repair(components: components, warnings: &warnings), warnings)
    }

    private static func repair(components: [Component], warnings: inout [FlashValidationWarning]) -> [Component] {
        components.map { repair(component: $0, warnings: &warnings) }
    }

    private static func repair(component: Component, warnings: inout [FlashValidationWarning]) -> Component {
        let repairedChildren = component.children.map { repair(components: $0, warnings: &warnings) }
        let repairedSteps = component.steps?.map { step in
            WizardStep(id: step.id, title: step.title, children: repair(components: step.children, warnings: &warnings))
        }

        let repairedValue: Double?
        switch component.type {
        case "progress", "meter", "progress_ring":
            repairedValue = component.value.map { min(1, max(0, $0)) }
            if repairedValue != component.value {
                warnings.append(.init(componentID: component.id, message: "\(component.type) value clamped to 0...1"))
            }
        case "rating":
            repairedValue = component.value.map { min(5, max(0, $0)) }
            if repairedValue != component.value {
                warnings.append(.init(componentID: component.id, message: "rating value clamped to 0...5"))
            }
        default:
            repairedValue = component.value
        }

        let repairedURL: String?
        if let src = component.src, !src.isEmpty, src.contains("://") == false {
            repairedURL = "https://" + src
            warnings.append(.init(componentID: component.id, message: "Normalized URL for \(component.type)"))
        } else {
            repairedURL = component.src
        }

        return Component(
            id: component.id,
            type: component.type,
            children: repairedChildren,
            items: component.items,
            content: component.content,
            icon: component.icon,
            style: component.style,
            weight: component.weight,
            color: component.color,
            background: component.background,
            alignment: component.alignment,
            padding: component.padding,
            cornerRadius: component.cornerRadius,
            columns: component.columns,
            spacing: component.spacing,
            itemWidth: component.itemWidth,
            opacity: component.opacity.map { min(1, max(0, $0)) },
            rotation: component.rotation,
            scale: component.scale,
            offsetX: component.offsetX,
            offsetY: component.offsetY,
            minWidth: component.minWidth,
            maxWidth: component.maxWidth,
            aspectRatio: component.aspectRatio.map { max(0.1, $0) },
            zIndex: component.zIndex,
            value: repairedValue,
            border: component.border,
            shadow: component.shadow.map { max(0, $0) },
            minHeight: component.minHeight.map { max(0, $0) },
            action: component.action,
            name: component.name,
            src: repairedURL,
            subtitle: component.subtitle,
            urls: component.urls?.map { $0.contains("://") ? $0 : "https://" + $0 },
            latitude: component.latitude,
            longitude: component.longitude,
            duration: component.duration.map { max(0, $0) },
            steps: repairedSteps,
            mode: component.mode
        )
    }
}
