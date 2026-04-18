//
//  CarouselCard.swift
//  H3-CoqueGuide
//
//  Tarjeta del carrusel de galerías en la pantalla principal.
//

import SwiftUI
import UIKit

struct CarouselCard: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen de fondo (con fallback si el asset no existe)
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                imageFallback
            }

            // Overlay gradiente oscuro en la parte inferior
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.65)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Texto sobre la imagen
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    /// Placeholder cuando el asset no existe: evita que el usuario vea un
    /// hueco gris sin contexto en el carrusel.
    private var imageFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))

            VStack(spacing: 8) {
                Image(systemName: "photo.slash")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(L10n.carouselImageUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
