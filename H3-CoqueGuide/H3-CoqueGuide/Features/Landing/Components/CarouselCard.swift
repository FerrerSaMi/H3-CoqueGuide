//
//  CarouselCard.swift
//  H3-CoqueGuide
//
//  Tarjeta del carrusel de galerías en la pantalla principal.
//

import SwiftUI

struct CarouselCard: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen de fondo
            Image(imageName)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 20))

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
}
