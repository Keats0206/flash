import SwiftUI

// MARK: - Palette (viewer-only; not part of MicroApp JSON)

struct SkinPalette: Equatable {
    var accent: Color
    var success: Color
    var danger: Color
    var warning: Color

    static func appDefault(appAccentHex: String) -> SkinPalette {
        SkinPalette(
            accent: Color(hex: appAccentHex),
            success: .green,
            danger: .red,
            warning: .orange
        )
    }

    static let previewFallback = SkinPalette(
        accent: Color(red: 0, green: 0.48, blue: 1),
        success: .green,
        danger: .red,
        warning: .orange
    )
}


// MARK: - Environment

private struct SkinPaletteKey: EnvironmentKey {
    static let defaultValue = SkinPalette.previewFallback
}

extension EnvironmentValues {
    var skinPalette: SkinPalette {
        get { self[SkinPaletteKey.self] }
        set { self[SkinPaletteKey.self] = newValue }
    }
}

