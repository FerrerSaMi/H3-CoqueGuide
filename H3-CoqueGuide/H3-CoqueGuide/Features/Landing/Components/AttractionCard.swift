//
//  AttractionCard.swift
//  H3-CoqueGuide
//
//  Tarjeta visual de una atracción del museo.
//

import SwiftUI

struct AttractionCard: View {
    let attraction: Attraction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Ícono
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(attraction.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: attraction.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(attraction.color)
                }

                // Textos
                VStack(alignment: .leading, spacing: 3) {
                    Text(attraction.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(attraction.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 140)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(attraction.name)
        .accessibilityHint("Abre CoqueGuide con información sobre \(attraction.name)")
    }
}
