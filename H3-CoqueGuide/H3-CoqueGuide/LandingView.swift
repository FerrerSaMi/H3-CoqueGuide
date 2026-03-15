//
//  LandingView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 12/03/26.
//

import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // MARK: - Logo & Title
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundStyle(.tint)

                        Text("CoqueGuide")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Tu guía definitiva de fundas")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // MARK: - Acciones principales (placeholders para futuras historias de usuario)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: PlaceholderView(title: "Atracciones")) {
                            GridButton(title: "Atracciones", icon: "star", accent: true)
                        }
                        NavigationLink(destination: CamScannerView()) {
                            GridButton(title: "Escaneo", icon: "arkit")
                        }
                        NavigationLink(destination: MapaView()) {
                            GridButton(title: "Mapa", icon: "map")
                        }
                        NavigationLink(destination: SurveyView()) {
                            GridButton(title: "Encuesta", icon: "list.clipboard", accent: true)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                NavigationLink(destination: PlaceholderView(title: "Chatbot")) {
                    Image("Coque")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                .padding(.trailing, 170)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Botón de cuadrícula
struct GridButton: View {
    let title: String
    let icon: String
    var accent: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(accent ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        .foregroundStyle(accent ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent ? Color.clear : Color(.separator), lineWidth: 1)
        )
    }
}

// MARK: - Placeholder para ramas futuras
struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text("Próximamente")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LandingView()
}
