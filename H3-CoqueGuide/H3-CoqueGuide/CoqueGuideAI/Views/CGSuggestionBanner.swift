//
//  CGSuggestionBanner.swift
//  CoqueGuideAI
//
//  Banner de sugerencia proactiva no invasiva.
//  Aparece encima del botón flotante durante unos segundos
//  para captar la atención del visitante de forma contextual.
//

import SwiftUI

// MARK: - Banner de sugerencia

/// Banner compacto que muestra una sugerencia proactiva al visitante.
/// El visitante puede tocar el banner para iniciar la conversación,
/// o descartarlo con el botón "×".
struct CGSuggestionBanner: View {

    let suggestion: CGSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            // Ícono de la sugerencia
            Image(systemName: suggestion.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            // Texto de la sugerencia
            Text(suggestion.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Botón de descarte
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.14),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .onTapGesture(perform: onAccept)
    }
}
