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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

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
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 360, maxHeight: UIScreen.main.bounds.height * 0.65)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    SimpleCardView(
        title: "Bienvenido al CoqueScan",
        description: """
        Explora el museo de forma inteligente con nuestro escáner.

        Para escanear objetos: Apunta la cámara y presiona el botón circular. El sistema identificará el objeto y te dará una descripción detallada.

        Para traducir texto: Presiona "Extraer Texto" para leer automáticamente el texto visible, luego tradúcelo a tu idioma preferido.
        """,
        actionTitle: "Comenzar",
        action: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
