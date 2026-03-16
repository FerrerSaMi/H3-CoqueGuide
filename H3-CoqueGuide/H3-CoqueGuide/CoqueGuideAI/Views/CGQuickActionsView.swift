//
//  CGQuickActionsView.swift
//  CoqueGuideAI
//
//  Fila horizontal de chips de acciones rápidas dentro del panel.
//

import SwiftUI

// MARK: - Contenedor de acciones rápidas

/// Scroll horizontal con chips seleccionables para las acciones más comunes.
struct CGQuickActionsView: View {

    let actions: [CGQuickAction]
    let onSelect: (CGQuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    CGQuickActionChip(action: action) {
                        onSelect(action)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Chip individual

private struct CGQuickActionChip: View {

    let action: CGQuickAction
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        // Efecto press manual para mayor control visual
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
