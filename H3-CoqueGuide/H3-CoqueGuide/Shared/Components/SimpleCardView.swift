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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 360, maxHeight: UIScreen.main.bounds.height * 0.68)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 22)
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    SimpleCardView(
        title: "Bienvenido a CoqueGuide",
        description: "Explora la colección del museo con una guía simple y moderna. Pulsa continuar para seguir.",
        actionTitle: "Continuar",
        action: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}