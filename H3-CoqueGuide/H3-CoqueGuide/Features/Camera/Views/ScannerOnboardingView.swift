//
//  ScannerOnboardingView.swift
//  H3-CoqueGuide
//
//  Onboarding específico del escáner de objetos.
//  Se muestra una sola vez — persiste el flag en UserDefaults.
//
//  Estética: idéntica a OnboardingView (gradiente naranja, tipografía, animaciones).
//

import SwiftUI

struct ScannerOnboardingView: View {
    
    /// Callback cuando el usuario termina el onboarding.
    let onFinish: () -> Void
    
    @State private var currentPage: Int = 0
    
    private let totalPages = 3
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Contenido paginable
                TabView(selection: $currentPage) {
                    ScannerOnboardingWelcomePage()
                        .tag(0)
                    
                    ScannerOnboardingCapabilitiesPage()
                        .tag(1)
                    
                    ScannerOnboardingMissionPage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Indicador de paso + botón primario
                bottomBar
            }
        }
        .accessibilityAddTraits(.isModal)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                finish()
            } label: {
                Text("Saltar")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .accessibilityHint("Salta el onboarding del escáner")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 18) {
            // Indicador de pasos (dots)
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Paso \(currentPage + 1) de \(totalPages)")
            
            // Botón primario
            primaryButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    @ViewBuilder
    private var primaryButton: some View {
        switch currentPage {
        case 0, 1:
            Button {
                withAnimation {
                    currentPage += 1
                }
            } label: {
                primaryButtonLabel(text: "Siguiente")
            }
            .buttonStyle(.plain)
        default:
            Button {
                finish()
            } label: {
                primaryButtonLabel(text: "Comenzar a escanear")
            }
            .buttonStyle(.plain)
        }
    }
    
    private func primaryButtonLabel(text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                             Color(red: 0.85, green: 0.35, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.3), radius: 6, x: 0, y: 3)
    }
    
    private func finish() {
        AnalyticsService.shared.track("scanner_onboarding_completed", metadata: [
            "page": currentPage,
        ])
        UserDefaults.standard.set(true, forKey: "hasSeenScannerOnboarding")
        onFinish()
    }
}

// MARK: - Página 1: Bienvenida

private struct ScannerOnboardingWelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                                 Color(red: 0.85, green: 0.35, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)
                .background(
                    Circle()
                        .fill(Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.1))
                )
            
            VStack(spacing: 12) {
                Text("Escáner del Museo")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("Descubre los objetos del museo apuntando tu cámara")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Página 2: Capacidades

private struct ScannerOnboardingCapabilitiesPage: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("¿Qué puedes hacer?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("Tres formas de explorar Horno3")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 18) {
                capabilityRow(
                    icon: "cube.transparent.fill",
                    title: "Identificar objetos",
                    subtitle: "Escanea las piezas del museo para conocer su historia"
                )
                capabilityRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Extraer texto",
                    subtitle: "Lee letreros y placas — se traducen automáticamente"
                )
                capabilityRow(
                    icon: "sparkles",
                    title: "Preguntarle a Coque",
                    subtitle: "Haz preguntas sobre lo que escanees"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func capabilityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Página 3: Misión

private struct ScannerOnboardingMissionPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.15),
                                     Color(red: 0.85, green: 0.35, blue: 0.10).opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "target")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                                     Color(red: 0.85, green: 0.35, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Misión: Hide and Seek 🎯")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("Encuentra todos los objetos destacados del museo. Verás el progreso mientras escaneas.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ScannerOnboardingView { }
}
