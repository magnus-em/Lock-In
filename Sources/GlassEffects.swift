import SwiftUI

extension View {
    func glassCard<S: InsettableShape>(in shape: S) -> some View {
        background(shape.fill(.thinMaterial))
            .overlay(shape.strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    func glassCard(cornerRadius: CGFloat = 12) -> some View {
        glassCard(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassChrome() -> some View {
        background(.regularMaterial)
    }

    func glassChip() -> some View {
        background(
            Capsule().fill(.thinMaterial)
        )
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    func glassTabChip(selected: Bool) -> some View {
        background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? AnyShapeStyle(Color.accentColor.opacity(0.75)) : AnyShapeStyle(.thinMaterial))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(selected ? 0.0 : 0.06), lineWidth: 0.5)
        )
    }

    func popoverBackground() -> some View {
        background(.regularMaterial)
    }
}

@ViewBuilder
func glassChipGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
}
