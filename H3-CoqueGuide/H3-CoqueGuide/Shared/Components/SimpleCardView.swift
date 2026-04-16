//
//  SimpleCardView.swift
//  H3-CoqueGuide
//
//  Componente reusable de tarjeta con título, descripción y acción.
//

import SwiftUI

struct SimpleCardView: View {
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void

    @State private var isVisible = false
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(contentOpacity * 0.8)
                    .offset(y: contentOffset * 0.8)

                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .opacity(1)
                .offset(y: 0)
                .scaleEffect(1)
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 360, maxHeight: UIScreen.main.bounds.height * 0.75)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .offset(y: isVisible ? 0 : 40)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                isVisible = true
            }

            // Animar contenido con delay escalonado
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.8)) {
                    contentOpacity = 1
                    contentOffset = 0
                }
            }
        }
    }
}

#Preview {
    SimpleCardView(
        title: "Descubre el Museo con CoqueGuide",
        description: """
        ¡Bienvenido al escáner inteligente del museo!
        Escaneo de Objetos:
        Apunta tu cámara a cualquier objeto del museo y presiona el botón circular. CoqueGuide analizará la imagen y te dirá qué objeto es, con qué confianza lo identificó y te dará una descripción detallada generada por IA.
        Traducción de Texto
        Si ves texto en los objetos del museo, presiona "Extraer Texto" para que CoqueGuide lo lea automáticamente. Luego podrás traducirlo a tu idioma preferido entre Español, Inglés, Francés, Portugués, Coreano y Árabe.
        """,
        actionTitle: "Comenzar Exploración",
        action: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
