//
//  LandingView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 12/03/26.
//

import SwiftUI
import SwiftData
import Combine

struct LandingView: View {

    // MARK: - SwiftData
    @Environment(\.modelContext) private var modelContext

    // MARK: - CoqueGuide ViewModel
    // Coque hace sus llamadas al backend propio (Node + Postgres + Gemini server-side).
    // Si el backend está caído en tiempo de ejecución, BackendAIService devuelve un
    // mensaje de error natural al usuario (sin fallback a simulado, para que no se
    // mezclen fuentes de respuestas y los analíticos queden consistentes).
    @StateObject private var coqueGuideVM: CGViewModel = {
        let service: CGAIServiceProtocol = BackendAIService()
        return CGViewModel(aiService: service)
    }()

    // MARK: - Navegación
    @State private var navigationPath = NavigationPath()
    @State private var navigationCoordinator = CGNavigationCoordinator()

    // MARK: - Carrusel
    @State private var currentGalleryIndex: Int = 0
    let autoScrollTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    /// Los textos se calculan dinámicamente según el idioma del dispositivo.
    private var galleryItems: [(video: String, title: String, subtitle: String)] {
        [
            ("Galeria1", L10n.galleryExperiencesTitle,  L10n.galleryExperiencesSubtitle),   // Show del Horno
            ("Galeria2", L10n.galleryExhibitionsTitle,  L10n.galleryExhibitionsSubtitle),   // Laboratorio de Innovación
            ("Galeria3", L10n.galleryCultureTitle,      L10n.galleryCultureSubtitle),       // Show del planeta Tierra
            ("Galeria4", L10n.galleryExhibitionsTitle,  L10n.galleryExhibitionsSubtitle),   // Reacción en Cadena
            ("Galeria5", L10n.galleryHistoryTitle,      L10n.galleryHistorySubtitle),       // Galeria de Historia
            ("Galeria6", L10n.galleryExhibitionsTitle,  L10n.galleryExhibitionsSubtitle),   // Una ventana a la ciencia
            ("Galeria7", L10n.galleryExperiencesTitle,  L10n.galleryExperiencesSubtitle),   // Pase a la cima
            ("Galeria8", L10n.galleryMuseumTitle,       L10n.galleryMuseumSubtitle),        // Galeria de Acero
        ]
    }

    // MARK: - TabView
    /// Permite que el llamador (p.ej. onboarding que eligió "Comenzar encuesta")
    /// seleccione un tab inicial. Por defecto 0 (inicio).
    @Binding var selectedTab: Int
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false

    // Inits para mantener compatibilidad con `LandingView()` (sin binding) y
    // con la nueva entrada desde RootView (con binding).
    init(initialTab: Binding<Int>) {
        self._selectedTab = initialTab
    }

    init() {
        self._selectedTab = .constant(0)
    }

    // MARK: - Analytics
    @State private var hasTrackedAppOpen = false

    /// Contenido del card de CoqueGuide en home (computado para reflejar el idioma actual).
    private var homeInviteContent: CGHomeInviteContent { .default }

    /// Saludo dinámico según la hora del día (localizado al idioma del iPhone).
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return L10n.greetingMorning
        case 12..<18: return L10n.greetingAfternoon
        default:      return L10n.greetingEvening
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                // TAB 0: Inicio
                atraccionesTab
                    .tabItem {
                        Label(L10n.tabHome, systemImage: "house.fill")
                    }
                    .tag(0)

                // TAB 1: Escaneo
                CamScannerView()
                    .tabItem {
                        Label(L10n.tabScan, systemImage: "qrcode.viewfinder")
                    }
                    .tag(1)

                // TAB 2: Mapa
                MapaView()
                    .tabItem {
                        Label(L10n.tabMap, systemImage: "map.fill")
                    }
                    .tag(2)

                // TAB 3: Encuesta
                SurveyView()
                    .tabItem {
                        Label(L10n.tabProfile, systemImage: "checklist")
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
                    PlaceholderView(title: L10n.landingPlaceholderAttractions)
                        .onAppear { AnalyticsService.shared.track("events_opened") }
                        .trackScreenTime("events")
                case .scanning:
                    CamScannerView()
                case .survey:
                    SurveyView()
                case .chatbot:
                    PlaceholderView(title: L10n.landingPlaceholderChatbot)
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
            .onAppear {
                coqueGuideVM.loadVisitorProfile(from: modelContext)
                Task { await CGEventService.shared.refresh() }

                // Analytics: app_opened una sola vez + bindear visitor_id si ya hay perfil.
                if !hasTrackedAppOpen {
                    hasTrackedAppOpen = true
                    AnalyticsService.shared.track("app_opened")
                }
                let descriptor = FetchDescriptor<ExcursionUserProfile>(
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
                if let profile = try? modelContext.fetch(descriptor).first {
                    AnalyticsService.shared.setVisitor(profile.backendID)
                }
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                // Recargar perfil al volver del tab de Encuesta
                if oldTab == 3 && newTab != 3 {
                    coqueGuideVM.loadVisitorProfile(from: modelContext)
                }
            }
        }
        .environmentObject(coqueGuideVM)
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    }

    // MARK: - Animación de aparición
    @State private var sectionsAppeared = false

    // MARK: - Tab Content: Atracciones

    private var atraccionesTab: some View {
        GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
                        headerSection
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : -20)

                        // MARK: - Carrusel de Galerías
                        carouselSection(isLandscape: isLandscape, proxyHeight: proxy.size.height)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .scaleEffect(sectionsAppeared ? 1 : 0.95)

                        coqueGuideInviteCard
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 30)

                        // MARK: - Cómo usar la app
                        howToUseSection
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 30)

                        // MARK: - Atracciones del museo
                        attractionsSection
                            .padding(.top, 10)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 30)

                        // MARK: - Ubicación del museo
                        MuseumLocationCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 30)

                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                        sectionsAppeared = true
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .trackScreenTime("home")
    }

    // MARK: - Header

    private var headerSection: some View {
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isDarkModeEnabled.toggle()
                    }
                } label: {
                    Image(systemName: isDarkModeEnabled ? "sun.max.fill" : "moon.fill")
                        .scalingFont(size: 16, weight: .medium)
                        .foregroundStyle(isDarkModeEnabled ? .yellow : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isDarkModeEnabled ? 360 : 0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isDarkModeEnabled)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDarkModeEnabled ? L10n.landingDarkModeToLight : L10n.landingDarkModeToDark)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Greeting
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(L10n.landingGreetingSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Carrusel

    private func carouselSection(isLandscape: Bool, proxyHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            TabView(selection: $currentGalleryIndex) {
                ForEach(0..<galleryItems.count, id: \.self) { index in
                    CarouselVideoCard(
                        videoName: galleryItems[index].video,
                        title: galleryItems[index].title,
                        subtitle: galleryItems[index].subtitle,
                        fallbackImageName: galleryItems[index].video
                    )
                    .tag(index)
                }
            }
            .frame(height: isLandscape ? max(320, proxyHeight * 0.62) : 280)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.horizontal, isLandscape ? 0 : 24)
            .onReceive(autoScrollTimer) { _ in
                guard selectedTab == 0 else { return }
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
    }

    // MARK: - CoqueGuide Invite Card

    private var coqueGuideInviteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con avatar y título
            HStack(spacing: 12) {
                Image("Coque")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.cgHomeTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(L10n.cgHeaderSubtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // Indicador de estado
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(L10n.cgStatusBadge)
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
            Text(L10n.cgHomeMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            // CTA primario — claramente tappable
            Button {
                coqueGuideVM.openPanel()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .scalingFont(size: 15, weight: .bold)
                    Text(L10n.cgHomeCTA)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.forward")
                        .scalingFont(size: 13, weight: .bold)
                }
                .foregroundStyle(Color(red: 0.85, green: 0.35, blue: 0.10))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(L10n.cgHomeCTA))

            // Separador sutil
            Text(L10n.cgQuickActionsLabel)
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 2)

            // Quick actions en columnas iguales
            HStack(spacing: 8) {
                ForEach(homeInviteContent.quickActions) { action in
                    quickActionChip(action) {
                        coqueGuideVM.openPanelWithMessage(action.message)
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.landingCGAccessibilityLabel)
    }

    private func quickActionChip(_ action: CGQuickAction, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 6) {
                Image(systemName: action.icon)
                    .scalingFont(size: 15, weight: .semibold)
                    .foregroundStyle(.white)

                Text(action.title)
                    .scalingFont(size: 12, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cómo funciona

    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.landingHowToUseTitle)
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 0) {
                howToUseStep(
                    icon: "qrcode.viewfinder",
                    title: L10n.landingStepScanTitle,
                    subtitle: L10n.landingStepScanSubtitle,
                    color: Color(red: 0.35, green: 0.70, blue: 0.50)
                )

                stepConnector

                howToUseStep(
                    icon: "sparkles",
                    title: L10n.landingStepAskTitle,
                    subtitle: L10n.landingStepAskSubtitle,
                    color: Color(red: 0.93, green: 0.45, blue: 0.15)
                )

                stepConnector

                howToUseStep(
                    icon: "map.fill",
                    title: L10n.landingStepExploreTitle,
                    subtitle: L10n.landingStepExploreSubtitle,
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
                    .scalingFont(size: 20, weight: .semibold)
                    .foregroundStyle(color)
            }

            Text(title)
                .scalingFont(size: 12, weight: .bold, relativeTo: .caption)
                .foregroundStyle(.primary)

            Text(subtitle)
                .scalingFont(size: 10, relativeTo: .caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var stepConnector: some View {
        Image(systemName: "chevron.forward")
            .scalingFont(size: 12, weight: .bold)
            .foregroundStyle(.tertiary)
            .frame(width: 20)
    }

    // MARK: - Atracciones Section

    private var attractionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.landingAttractionsTitle)
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

#Preview {
    LandingView()
}
