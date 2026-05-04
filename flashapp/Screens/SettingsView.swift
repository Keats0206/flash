import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var modelId: String = Config.anthropicModel

    private struct ModelPreset: Identifiable {
        let label: String
        let id: String
    }

    private static let modelPresets: [ModelPreset] = [
        ModelPreset(label: "Haiku 4.5 (fast)", id: "claude-haiku-4-5"),
        ModelPreset(label: "Sonnet 4 (balanced)", id: "claude-sonnet-4-20250514"),
        ModelPreset(label: "Opus 4 (best)", id: "claude-opus-4-20250514"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                modelSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Config.setAnthropicModel(modelId)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var modelSection: some View {
        Section {
            ForEach(Self.modelPresets) { preset in
                presetButton(for: preset)
            }
        } header: {
            Text("AI Model")
        } footer: {
            Text("Faster models use fewer coins per build.")
        }
    }

    private func presetButton(for preset: ModelPreset) -> some View {
        Button {
            modelId = preset.id
        } label: {
            HStack {
                Text(preset.label)
                    .foregroundColor(.primary)
                Spacer()
                if modelId == preset.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
