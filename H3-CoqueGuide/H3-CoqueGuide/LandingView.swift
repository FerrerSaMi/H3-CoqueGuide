//
//  LandingView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 12/03/26.
//

import SwiftUI

struct LandingView: View {

    // MARK: - CoqueGuide ViewModel
    // Usa Claude API si hay key en Secrets.plist, sino usa servicio simulado
    @StateObject private var coqueGuideVM: CGViewModel = {
        let service: CGAIServiceProtocol = ClaudeAIService.fromSecretsPlist() ?? CGSimulatedAIService()
        return CGViewModel(aiService: service)
    }()

    // MARK: - Navegación
    @State private var navigationPath = NavigationPath()
    @State private var navigationCoordinator = CGNavigationCoordinator()
    
    // MARK: - Carrusel
    @State private var currentGalleryIndex: Int = 0
    private let galleryImages = ["Galeria1", "Galeria2", "Galeria3", "Galeria4", "Galeria5"]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
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

                        Text("Museo del Acero Horno3")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // MARK: - Carrusel de Galerías
                    TabView(selection: $currentGalleryIndex) {
                        ForEach(0..<galleryImages.count, id: \.self) { index in
                            Image(galleryImages[index])
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 280)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                    Spacer()

                    // MARK: - Barra de opciones inferior
                    VStack(spacing: 0) {
                        // Separador
                        Divider()

                        // Grid de 4 botones
                        HStack(spacing: 12) {
                            NavigationLink(value: CGAppDestination.events) {
                                GridButton(title: "Atracciones", icon: "star", accent: true)
                            }
                            NavigationLink(destination: CamScannerView()) {
                                GridButton(title: "Escaneo", icon: "arkit")
                            }
                            NavigationLink(destination: MapaView()) {
                                GridButton(title: "Mapa", icon: "map")
                            }
                            NavigationLink(value: CGAppDestination.survey) {
                                GridButton(title: "Encuesta", icon: "list.clipboard", accent: true)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: CGAppDestination.self) { destination in
                switch destination {
                case .map:
                    MapaView()
                case .events:
                    PlaceholderView(title: "Atracciones")
                case .scanning:
                    CamScannerView()
                case .survey:
                    SurveyView()
                case .chatbot:
                    PlaceholderView(title: "Chatbot")
                }
            }
            // MARK: - Integración de CoqueGuide
            .coqueGuideOverlay(viewModel: coqueGuideVM)
            .environment(navigationCoordinator)
            .onChange(of: navigationCoordinator.pendingDestination) { _, newValue in
                if let destination = newValue {
                    // Cerrar el panel primero, luego navegar
                    coqueGuideVM.isPanelOpen = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigationPath.append(destination)
                        navigationCoordinator.pendingDestination = nil
                    }
                }
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(accent ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        .foregroundStyle(accent ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
