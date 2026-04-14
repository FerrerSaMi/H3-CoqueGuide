//
//  CGActionCardView.swift
//  CoqueGuideAI
//
//  Tarjeta de acción interactiva dentro del panel del asistente.
//

import SwiftUI

struct CGActionCardView: View {

    let card: CGActionCard
    @Environment(CGNavigationCoordinator.self) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icono + Título
            HStack(spacing: 10) {
                Image(systemName: card.icon)
                    .font(.title3)
                    .foregroundStyle(.accent)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if let subtitle = card.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Descripción
            if let description = card.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Botón de acción
            if card.action != nil {
                Button {
                    handleAction()
                } label: {
                    Text(card.cardType.actionLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 280)
    }

    private func handleAction() {
        guard let action = card.action else { return }
        switch action {
        case .navigate(let destination):
            navigator.navigate(to: destination)
        case .sendMessage:
            break // Manejado por el ViewModel si se necesita
        }
    }
}
