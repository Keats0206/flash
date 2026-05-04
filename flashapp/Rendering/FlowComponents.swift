import SwiftUI

// MARK: - Wizard (first-class multi-step flow)

struct CWizard: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    @State private var currentIndex = 0

    private var steps: [WizardStep] { c.steps ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if steps.isEmpty {
                Text("Add a \"steps\" array to this wizard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                progressHeader

                if let title = steps[currentIndex].title, !title.isEmpty {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps[currentIndex].children.enumerated()), id: \.offset) { _, child in
                        ComponentView(c: child)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                navigationRow
            }
        }
        .padding(c.padding ?? 0)
        .onChange(of: steps.count) { _, count in
            if currentIndex >= count { currentIndex = max(0, count - 1) }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentIndex ? palette.accent : Color.secondary.opacity(0.25))
                        .frame(height: 4)
                }
            }
            Text("Step \(currentIndex + 1) of \(steps.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var navigationRow: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    currentIndex = max(0, currentIndex - 1)
                }
            } label: {
                Text("Back")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(currentIndex == 0)

            if currentIndex < steps.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        currentIndex += 1
                    }
                } label: {
                    Text("Next")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
            }
        }
        .padding(.top, 4)
    }
}
