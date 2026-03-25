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
    
    // MARK: - TabView
    @State private var selectedTab: Int = 0

    private let homeInviteContent = CGHomeInviteContent.default

    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                // TAB 0: Inicio
                atraccionesTab
                    .tabItem {
                        Label("Inicio", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // TAB 1: Escaneo
                CamScannerView()
                    .tabItem {
                        Label("Escaneo", systemImage: "qrcode.viewfinder")
                    }
                    .tag(1)
                
                // TAB 2: Mapa
                MapaView()
                    .tabItem {
                        Label("Mapa", systemImage: "map.fill")
                    }
                    .tag(2)
                
                // TAB 3: Encuesta
                SurveyView()
                    .tabItem {
                        Label("Encuesta", systemImage: "checklist")
                    }
                    .tag(3)
            }
            .tint(Color.accentColor)
            .environment(navigationCoordinator)
            .coqueGuideOverlay(viewModel: coqueGuideVM, hideFloatingButton: selectedTab == 0)
            .onChange(of: navigationCoordinator.pendingDestination) { _, newValue in
                if let destination = newValue {
                    coqueGuideVM.isPanelOpen = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigationPath.append(destination)
                        navigationCoordinator.pendingDestination = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Content: Atracciones
    private var atraccionesTab: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // MARK: - Logo
                    Image("horno3Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .padding(.top, 20)

                    // MARK: - Carrusel de Galerías
                    VStack(spacing: 12) {
                        TabView(selection: $currentGalleryIndex) {
                            ForEach(0..<galleryImages.count, id: \.self) { index in
                                CarouselCard(imageName: galleryImages[index])
                                    .tag(index)
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .padding(.horizontal, 24)

                        // MARK: - Indicadores personalizados del carrusel
                        HStack(spacing: 8) {
                            ForEach(0..<galleryImages.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentGalleryIndex ? Color.accentColor : Color.gray.opacity(0.3))
                                    .frame(width: index == currentGalleryIndex ? 24 : 8, height: 6)
                                    .animation(.easeInOut(duration: 0.3), value: currentGalleryIndex)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    coqueGuideInviteCard
                        .padding(.horizontal, 20)
                        .padding(.top, 6)

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("CoqueGuide")
            .navigationSubtitle("Museo del Acero Horno3")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }

    private var coqueGuideInviteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.accentColor.opacity(0.22))
                    .frame(width: 24, height: 24)

                Text(homeInviteContent.title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(homeInviteContent.message)
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 10, alignment: .leading)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(homeInviteContent.quickActions) { action in
                    quickActionChip(action.title) {
                        if action.icon == "map" {
                            navigationPath.append(CGAppDestination.map)
                        } else if action.icon == "message.fill" {
                            coqueGuideVM.openPanel()
                        } else {
                            coqueGuideVM.openPanel()
                            coqueGuideVM.handleQuickAction(action)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func quickActionChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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

// MARK: - Tarjeta del Carrusel
struct CarouselCard: View {
    let imageName: String

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            // Imagen de fondo
            Image(imageName)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Overlay gradiente oscuro en la parte inferior
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.7)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Texto contextual
            VStack(alignment: .center, spacing: 4) {
                Text("Galería")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Desliza para explorar")
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    LandingView()
}
