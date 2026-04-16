//
//  CGPanelSkeleton.swift
//  CoqueGuideAI
//
//  Placeholder ligero que se muestra durante los primeros milisegundos
//  mientras el sheet del panel termina de presentarse. Tiene mucho menos
//  coste de render que el panel real (sin ScrollView, sin ForEach, sin
//  TextField, sin custom shapes), lo que permite que la animación del
//  sheet de iOS sea fluida. Tras ~200 ms se reemplaza por el contenido real.
//

import SwiftUI

// MARK: - Skeleton del panel

struct CGPanelSkeleton: View {

    /// Alterna el shimmer para dar sensación de "cargando".
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 0) {

            // Área de mensajes (un bubble fake)
            VStack(alignment: .leading, spacing: 14) {
                skeletonBubble(height: 120, width: 260)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            // Fila de acciones rápidas (chips fake)
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(placeholderColor)
                        .frame(width: 94, height: 32)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Input bar fake
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(placeholderColor)
                    .frame(height: 44)

                Circle()
                    .fill(placeholderColor)
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Shimmer suave para que no se vea estático.
            withAnimation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
            ) {
                shimmer = true
            }
        }
    }

    // MARK: - Helpers visuales

    private var placeholderColor: Color {
        Color(.systemGray5).opacity(shimmer ? 0.55 : 1.0)
    }

    private func skeletonBubble(height: CGFloat, width: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar placeholder
            Circle()
                .fill(placeholderColor)
                .frame(width: 32, height: 32)

            // Bubble placeholder
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(placeholderColor)
                .frame(width: width, height: height)

            Spacer(minLength: 40)
        }
    }
}

// MARK: - Preview

#Preview {
    CGPanelSkeleton()
}
