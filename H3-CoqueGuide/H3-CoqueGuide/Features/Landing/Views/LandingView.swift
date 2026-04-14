//
//  LandingView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 12/03/26.
//

import SwiftUI
import Combine

struct LandingView: View {

    // MARK: - CoqueGuide ViewModel
    // Usa Gemini API si hay key en Secrets.plist, sino usa servicio simulado
    @StateObject private var coqueGuideVM: CGViewModel = {
        let service: CGAIServiceProtocol = GeminiAIService.fromSecretsPlist() ?? CGSimulatedAIService()
        return CGViewModel(aiService: service)
    }()

    // MARK: - Navegación
    @State private var navigationPath = NavigationPath()
    @State private var navigationCoordinator = CGNavigationCoordinator()
    
    // MARK: - Carrusel
    @State private var currentGalleryIndex: Int = 0
    let autoScrollTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let galleryItems: [(image: String, title: String, subtitle: String)] = [
        ("Galeria1", "Museo del Acero", "Horno3 - Monterrey, NL"),
        ("Galeria2", "Historia Industrial", "Conoce el legado siderurgico"),
        ("Galeria3", "Exhibiciones", "Ciencia, arte y tecnologia"),
        ("Galeria4", "Experiencias", "Recorridos interactivos"),
        ("Galeria5", "Cultura y Aprendizaje", "Un mundo por descubrir"),
    ]
    
    // MARK: - TabView
    @State private var selectedTab: Int = 0
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false

    private let homeInviteContent = CGHomeInviteContent.default

    /// Saludo dinámico según la hora del día
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "Buenos días"
        case 12..<18:
            return "Buenas tardes"
        default:
            return "Buenas noches"
        }
    }

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
            .coqueGuideOverlay(viewModel: coqueGuideVM, hideFloatingButton: selectedTab == 0, navigator: navigationCoordinator)
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
        .environmentObject(coqueGuideVM)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    }
    
    // MARK: - Tab Content: Atracciones
    private var atraccionesTab: some View {
        GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
                        VStack(spacing: 16) {
                            HStack(alignment: .center) {
                                Image("horno3Logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Museo del Acero")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("Horno3")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    isDarkModeEnabled.toggle()
                                } label: {
                                    Image(systemName: isDarkModeEnabled ? "sun.max.fill" : "moon.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(isDarkModeEnabled ? .yellow : .secondary)
                                        .frame(width: 36, height: 36)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                            // Greeting
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greetingText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Explora todo lo que el museo tiene para ti")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        }

                        // MARK: - Carrusel de Galerías
                        VStack(spacing: 12) {
                            TabView(selection: $currentGalleryIndex) {
                                ForEach(0..<galleryItems.count, id: \.self) { index in
                                    CarouselCard(
                                        imageName: galleryItems[index].image,
                                        title: galleryItems[index].title,
                                        subtitle: galleryItems[index].subtitle
                                    )
                                    .tag(index)
                                }
                            }
                            .frame(height: isLandscape ? max(320, proxy.size.height * 0.62) : 280)
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .padding(.horizontal, isLandscape ? 0 : 24)
                            .onReceive(autoScrollTimer) { _ in
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentGalleryIndex = (currentGalleryIndex + 1) % galleryItems.count
                                }
                            }

                            HStack(spacing: 8) {
                                ForEach(0..<galleryItems.count, id: \.self) { index in
                                    Capsule()
                                        .fill(index == currentGalleryIndex ? Color.accentColor : Color.gray.opacity(0.3))
                                        .frame(width: index == currentGalleryIndex ? 24 : 8, height: 6)
                                        .animation(.easeInOut(duration: 0.3), value: currentGalleryIndex)
                                }
                            }
                            .padding(.horizontal, isLandscape ? 0 : 24)
                        }

                        coqueGuideInviteCard
                            .padding(.horizontal, 20)
                            .padding(.top, 14)

                        // MARK: - Cómo usar la app
                        howToUseSection
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        // MARK: - Atracciones del museo
                        attractionsSection
                            .padding(.top, 10)

                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
    }

    private var coqueGuideInviteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con avatar y título
            HStack(spacing: 12) {
                // Avatar con gradiente e ícono
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(homeInviteContent.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Tu asistente inteligente")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Indicador de estado
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Activo")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }

            // Mensaje de bienvenida
            Text(homeInviteContent.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.95))

            // Divider sutil
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 0.5)

            // Quick actions
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: 10, alignment: .leading)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(homeInviteContent.quickActions) { action in
                    quickActionChip(action) {
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.45, blue: 0.15), Color(red: 0.85, green: 0.35, blue: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func quickActionChip(_ action: CGQuickAction, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cómo usar la app
    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Como funciona")
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 0) {
                howToUseStep(
                    icon: "qrcode.viewfinder",
                    title: "Escanea",
                    subtitle: "Apunta a un objeto del museo",
                    color: Color(red: 0.35, green: 0.70, blue: 0.50)
                )

                stepConnector

                howToUseStep(
                    icon: "sparkles",
                    title: "Pregunta",
                    subtitle: "CoqueGuide te responde",
                    color: Color(red: 0.93, green: 0.45, blue: 0.15)
                )

                stepConnector

                howToUseStep(
                    icon: "map.fill",
                    title: "Explora",
                    subtitle: "Navega por el museo",
                    color: Color(red: 0.30, green: 0.50, blue: 0.75)
                )
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func howToUseStep(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var stepConnector: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.tertiary)
            .frame(width: 20)
    }

// MARK: - Atracciones Section
    private var attractionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Explora el museo")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Attraction.museumAttractions) { attraction in
                        AttractionCard(attraction: attraction) {
                            coqueGuideVM.openPanelWithMessage(attraction.message)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Modelo de Atraccion
struct Attraction: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let message: String

    static let museumAttractions: [Attraction] = [
        Attraction(
            name: "Horno Alto",
            subtitle: "Paseo por el icono del museo",
            icon: "flame.fill",
            color: Color(red: 0.93, green: 0.45, blue: 0.15),
            message: "Cuéntame sobre el Horno Alto del museo"
        ),
        Attraction(
            name: "Galeria del Acero",
            subtitle: "Historia de la siderurgia",
            icon: "building.columns.fill",
            color: Color(red: 0.30, green: 0.50, blue: 0.75),
            message: "¿Qué puedo encontrar en la Galería del Acero?"
        ),
        Attraction(
            name: "Show del Acero",
            subtitle: "Espectaculo en vivo",
            icon: "sparkles",
            color: Color(red: 0.85, green: 0.30, blue: 0.30),
            message: "¿De qué trata el Show del Acero?"
        ),
        Attraction(
            name: "Laboratorio",
            subtitle: "Ciencia interactiva",
            icon: "flask.fill",
            color: Color(red: 0.35, green: 0.70, blue: 0.50),
            message: "¿Qué actividades hay en el Laboratorio?"
        ),
        Attraction(
            name: "Mirador",
            subtitle: "Vista panoramica",
            icon: "binoculars.fill",
            color: Color(red: 0.55, green: 0.45, blue: 0.75),
            message: "Cuéntame sobre el Mirador del museo"
        ),
        Attraction(
            name: "Aceria",
            subtitle: "Proceso del acero",
            icon: "gearshape.2.fill",
            color: Color(red: 0.50, green: 0.55, blue: 0.60),
            message: "¿Qué puedo aprender en la Acería?"
        ),
    ]
}

// MARK: - Tarjeta de Atraccion
struct AttractionCard: View {
    let attraction: Attraction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Icono
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
    }
}

#Preview {
    LandingView()
}
